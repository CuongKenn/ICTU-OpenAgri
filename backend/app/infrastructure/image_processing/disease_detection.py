# Copyright (c) 2025 CuongKenn and ICTU-OpenAgri Contributors
# Licensed under the MIT License. See LICENSE file in the project root for full license information.

import os
import numpy as np
from PIL import Image
# import tensorflow as tf
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
            # cls._instance._load_resources()
        return cls._instance

    def _load_resources(self):
        """Load the model and class names."""
        print("Disease detection disabled: Tensorflow not installed")
        pass

    def predict(self, image_bytes: bytes) -> Dict[str, Any]:
        """
        Predict disease from an image.
        
        Args:
            image_bytes: The image data in bytes.
            
        Returns:
            A dictionary containing the top class name and confidence score.
        """
        raise NotImplementedError("Disease detection is temporarily disabled due to missing tensorflow dependency.")

# Global instance
disease_detection_service = DiseaseDetectionService()
