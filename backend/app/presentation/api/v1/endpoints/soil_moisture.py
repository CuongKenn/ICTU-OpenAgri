from fastapi import APIRouter, Depends
from app.application.dto.soil_moisture_dto import SoilMoistureRequest, SoilMoistureResponse
from app.application.use_cases.soil_moisture_use_cases import CalculateSoilMoistureUseCase
from app.domain.entities.user import User
from app.presentation.deps import get_current_user

router = APIRouter()

@router.post("/calculate", response_model=SoilMoistureResponse)
def calculate_soil_moisture(
    request: SoilMoistureRequest,
    use_case: CalculateSoilMoistureUseCase = Depends(CalculateSoilMoistureUseCase),
    current_user: User = Depends(get_current_user)
):
    """
    Calculate Soil Moisture Proxy from Sentinel-1 data.
    Downloads Sentinel-1 GRD data and processes VV band.
    Requires authentication.
    """
    return use_case.execute(request)
