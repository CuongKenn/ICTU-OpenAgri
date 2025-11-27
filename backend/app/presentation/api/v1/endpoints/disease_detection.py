from fastapi import APIRouter, UploadFile, File, HTTPException, Depends
from typing import List, Dict, Any
from app.infrastructure.image_processing.disease_detection import disease_detection_service
from app.presentation.deps import get_current_user
from app.domain.entities.user import User

router = APIRouter()

@router.post("/predict", response_model=Dict[str, Any])
async def predict_disease(
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user)
):
    """
    Predict disease from an uploaded image file.
    Requires authentication.
    """
    if not file.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="File must be an image")

    try:
        contents = await file.read()
        prediction = disease_detection_service.predict(contents)
        return prediction
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Prediction failed: {str(e)}")
