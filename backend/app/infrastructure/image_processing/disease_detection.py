# Copyright (c) 2025 CuongKenn and ICTU-OpenAgri Contributors
# Licensed under the MIT License. See LICENSE file in the project root for full license information.

import os
import numpy as np
from PIL import Image
import tensorflow as tf
from pathlib import Path
from typing import List, Dict, Any
import io
from .disease_info import DISEASE_INFO

class DiseaseDetectionService:
    _instance = None
    _model = None
    _class_names = None
    
    _vietnamese_names = {
        "Apple___Apple_scab": "Táo - Bệnh vảy táo",
        "Apple___Black_rot": "Táo - Bệnh thối đen",
        "Apple___Cedar_apple_rust": "Táo - Bệnh gỉ sắt tuyết tùng",
        "Apple___healthy": "Táo - Khỏe mạnh",
        "Bacterial Leaf Blight": "Lúa - Bệnh bạc lá vi khuẩn",
        "Blueberry___healthy": "Việt quất - Khỏe mạnh",
        "Brown Spot": "Lúa - Bệnh đốm nâu",
        "Cherry_(including_sour)___Powdery_mildew": "Anh đào - Bệnh phấn trắng",
        "Cherry_(including_sour)___healthy": "Anh đào - Khỏe mạnh",
        "Corn_(maize)___Cercospora_leaf_spot Gray_leaf_spot": "Ngô - Bệnh đốm lá xám",
        "Corn_(maize)___Common_rust_": "Ngô - Bệnh gỉ sắt thường",
        "Corn_(maize)___Northern_Leaf_Blight": "Ngô - Bệnh cháy lá lớn",
        "Corn_(maize)___healthy": "Ngô - Khỏe mạnh",
        "Grape___Black_rot": "Nho - Bệnh thối đen",
        "Grape___Esca_(Black_Measles)": "Nho - Bệnh Esca (Sởi đen)",
        "Grape___Leaf_blight_(Isariopsis_Leaf_Spot)": "Nho - Bệnh cháy lá",
        "Grape___healthy": "Nho - Khỏe mạnh",
        "Healthy Rice Leaf": "Lúa - Khỏe mạnh",
        "Leaf Blast": "Lúa - Bệnh đạo ôn lá",
        "Leaf scald": "Lúa - Bệnh cháy bìa lá",
        "Narrow Brown Leaf Spot": "Lúa - Bệnh đốm nâu hẹp",
        "Orange___Haunglongbing_(Citrus_greening)": "Cam - Bệnh vàng lá gân xanh",
        "Peach___Bacterial_spot": "Đào - Bệnh đốm vi khuẩn",
        "Peach___healthy": "Đào - Khỏe mạnh",
        "Pepper,_bell___Bacterial_spot": "Ớt chuông - Bệnh đốm vi khuẩn",
        "Pepper,_bell___healthy": "Ớt chuông - Khỏe mạnh",
        "Potato___Early_blight": "Khoai tây - Bệnh đốm vòng",
        "Potato___Late_blight": "Khoai tây - Bệnh mốc sương",
        "Potato___healthy": "Khoai tây - Khỏe mạnh",
        "Raspberry___healthy": "Mâm xôi - Khỏe mạnh",
        "Rice Hispa": "Lúa - Sâu gai",
        "Sheath Blight": "Lúa - Bệnh khô vằn",
        "Soybean___healthy": "Đậu nành - Khỏe mạnh",
        "Squash___Powdery_mildew": "Bí - Bệnh phấn trắng",
        "Strawberry___Leaf_scorch": "Dâu tây - Bệnh cháy lá",
        "Strawberry___healthy": "Dâu tây - Khỏe mạnh",
        "Tomato___Bacterial_spot": "Cà chua - Bệnh đốm vi khuẩn",
        "Tomato___Early_blight": "Cà chua - Bệnh đốm vòng",
        "Tomato___Late_blight": "Cà chua - Bệnh mốc sương",
        "Tomato___Leaf_Mold": "Cà chua - Bệnh mốc lá",
        "Tomato___Septoria_leaf_spot": "Cà chua - Bệnh đốm lá Septoria",
        "Tomato___Spider_mites Two-spotted_spider_mite": "Cà chua - Nhện đỏ",
        "Tomato___Target_Spot": "Cà chua - Bệnh đốm đích",
        "Tomato___Tomato_Yellow_Leaf_Curl_Virus": "Cà chua - Virus xoăn vàng lá",
        "Tomato___Tomato_mosaic_virus": "Cà chua - Virus khảm",
        "Tomato___healthy": "Cà chua - Khỏe mạnh"
    }

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super(DiseaseDetectionService, cls).__new__(cls)
            cls._instance._load_resources()
        return cls._instance

    def _load_resources(self):
        """Load the model and class names."""
        try:
            # Calculate paths relative to this file
            current_dir = Path(__file__).parent
            # backend/app/infrastructure/image_processing/ -> backend/ml_models/
            base_dir = current_dir.parent.parent.parent
            model_path = base_dir / "ml_models" / "leaf_disease_model.keras"
            class_names_path = base_dir / "ml_models" / "class_names.txt"

            print(f"Loading model from: {model_path}")
            self._model = tf.keras.models.load_model(model_path)
            
            print(f"Loading class names from: {class_names_path}")
            with open(class_names_path, "r") as f:
                self._class_names = [line.strip() for line in f.readlines()]
                
        except Exception as e:
            print(f"Error loading disease detection resources: {e}")
            # We might want to raise this or handle it gracefully depending on requirements
            # For now, we'll let it fail if called later if resources aren't loaded
            pass

    def predict(self, image_bytes: bytes) -> Dict[str, Any]:
        """
        Predict disease from an image.
        
        Args:
            image_bytes: The image data in bytes.
            
        Returns:
            A dictionary containing the top class name and confidence score.
        """
        if self._model is None or self._class_names is None:
            self._load_resources()
            if self._model is None:
                raise RuntimeError("Model not loaded successfully")

        try:
            # Preprocess image
            img = Image.open(io.BytesIO(image_bytes))
            img = img.convert('RGB')
            img = img.resize((224, 224)) # Assuming standard input size, adjust if needed
            
            img_array = tf.keras.preprocessing.image.img_to_array(img)
            img_array = tf.expand_dims(img_array, 0) # Create a batch

            # Predict
            predictions = self._model.predict(img_array)
            score = predictions[0]  # Model already has softmax activation

            # Get top prediction
            predicted_index = np.argmax(score)
            class_name = self._class_names[predicted_index]
            confidence = float(score[predicted_index])
            
            vietnamese_name = self._vietnamese_names.get(class_name, class_name)
            disease_info = DISEASE_INFO.get(class_name, {})
            
            result = {
                "class_name": vietnamese_name,
                "original_name": class_name,
                "confidence": confidence,
                "description": disease_info.get("description", ""),
                "symptoms": disease_info.get("symptoms", []),
                "treatment": disease_info.get("treatment", []),
                "prevention": disease_info.get("prevention", []),
                "severity": disease_info.get("severity", "")
            }
            
            return result

        except Exception as e:
            print(f"Error during prediction: {e}")
            raise e

# Global instance
disease_detection_service = DiseaseDetectionService()
