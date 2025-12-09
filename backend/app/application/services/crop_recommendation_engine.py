import json
import os
import logging
from typing import List, Dict, Optional
from app.domain.entities.soil_analysis import SoilProperties, CropRecommendation

logger = logging.getLogger(__name__)

class CropRecommendationEngine:
    """
    Engine to recommend crops based on soil properties using rule-based logic.
    """
    
    def __init__(self, data_path: str = "data/crop_requirements.json"):
        self.data_path = data_path
        self.crops_data = self._load_data()

    def _load_data(self) -> Dict:
        try:
            # Adjust path if running from different context
            if not os.path.exists(self.data_path):
                # Try absolute path relative to project root if relative fails
                # Assuming app is running from backend/
                alt_path = os.path.join(os.getcwd(), self.data_path)
                if not os.path.exists(alt_path):
                     # Try going up one level
                    alt_path = os.path.join(os.getcwd(), "..", self.data_path)
                
                if os.path.exists(alt_path):
                    self.data_path = alt_path
            
            with open(self.data_path, 'r', encoding='utf-8') as f:
                return json.load(f)
        except Exception as e:
            logger.error(f"Failed to load crop requirements: {e}")
            return {}

    def recommend(self, soil: SoilProperties, top_n: int = 5) -> List[CropRecommendation]:
        recommendations = []
        
        for crop_key, requirements in self.crops_data.items():
            score = 0.0
            reasons = []
            warnings = []
            
            # 1. Check pH (Critical)
            if soil.ph_water:
                ph_min, ph_max = requirements.get("ph_range", [0, 14])
                if ph_min <= soil.ph_water <= ph_max:
                    score += 40 # High weight for pH
                    reasons.append(f"Độ pH ({soil.ph_water:.1f}) phù hợp ({ph_min}-{ph_max})")
                elif abs(soil.ph_water - ph_min) < 0.5 or abs(soil.ph_water - ph_max) < 0.5:
                    score += 20
                    warnings.append(f"Độ pH ({soil.ph_water:.1f}) hơi lệch so với tối ưu ({ph_min}-{ph_max})")
                else:
                    warnings.append(f"Độ pH ({soil.ph_water:.1f}) không phù hợp ({ph_min}-{ph_max})")
            
            # 2. Check Texture
            if soil.soil_texture:
                preferred = requirements.get("preferred_soil_texture", [])
                # Simple string matching or partial matching
                if soil.soil_texture in preferred:
                    score += 30
                    reasons.append(f"Kết cấu đất {soil.soil_texture} rất phù hợp")
                elif any(t in soil.soil_texture for t in preferred): # e.g. "Sandy Loam" matches "Loam" loosely
                    score += 15
                    reasons.append(f"Kết cấu đất {soil.soil_texture} chấp nhận được")
                else:
                    warnings.append(f"Kết cấu đất {soil.soil_texture} không tối ưu (Thích hợp: {', '.join(preferred)})")
            
            # 3. Check Nitrogen (if available)
            if soil.nitrogen and "nitrogen_min" in requirements:
                min_n = requirements["nitrogen_min"]
                if soil.nitrogen >= min_n:
                    score += 20
                    reasons.append("Hàm lượng đạm đủ")
                else:
                    score += 10
                    warnings.append("Đất hơi nghèo đạm, cần bón thêm")
            else:
                # If no N data, give neutral score
                score += 10
            
            # Normalize score to 100 max roughly
            final_score = min(100.0, score)
            
            if final_score > 30: # Only return relevant crops
                recommendations.append(CropRecommendation(
                    crop_name=requirements["name"],
                    crop_name_vi=requirements["name_vi"],
                    suitability_score=final_score,
                    reasons=reasons,
                    warnings=warnings,
                    ideal_conditions=requirements
                ))
        
        # Sort by score desc
        recommendations.sort(key=lambda x: x.suitability_score, reverse=True)
        
        return recommendations[:top_n]
