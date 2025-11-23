from typing import List
from fastapi import APIRouter, Depends, HTTPException
from app.application.dto.farm_dto import FarmAreaCreateDTO, FarmAreaResponseDTO
from app.application.use_cases.farm_use_cases import CreateFarmAreaUseCase, GetUserFarmsUseCase
from app.infrastructure.repositories.farm_repository_impl import SQLAlchemyFarmRepository
from app.presentation.deps import get_current_user, get_farm_repository
from app.domain.entities.user import User

router = APIRouter()

def get_create_farm_use_case(
    farm_repository: SQLAlchemyFarmRepository = Depends(get_farm_repository)
) -> CreateFarmAreaUseCase:
    return CreateFarmAreaUseCase(farm_repository)

def get_user_farms_use_case(
    farm_repository: SQLAlchemyFarmRepository = Depends(get_farm_repository)
) -> GetUserFarmsUseCase:
    return GetUserFarmsUseCase(farm_repository)

@router.post("/", response_model=FarmAreaResponseDTO)
async def create_farm_area(
    farm_data: FarmAreaCreateDTO,
    use_case: CreateFarmAreaUseCase = Depends(get_create_farm_use_case),
    current_user: User = Depends(get_current_user)
):
    return await use_case.execute(current_user.id, farm_data)

@router.get("/", response_model=List[FarmAreaResponseDTO])
async def get_my_farms(
    use_case: GetUserFarmsUseCase = Depends(get_user_farms_use_case),
    current_user: User = Depends(get_current_user)
):
    return await use_case.execute(current_user.id)
