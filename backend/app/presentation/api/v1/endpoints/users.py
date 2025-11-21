"""
User API endpoints.
"""
from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.application.dto.user_dto import CreateUserDTO, UserDTO, UpdateUserDTO
from app.application.use_cases.user_use_cases import (
    CreateUserUseCase,
    GetUserByIdUseCase,
    GetAllUsersUseCase,
    UpdateUserUseCase,
    DeleteUserUseCase
)
from app.infrastructure.database.database import get_db
from app.infrastructure.repositories.user_repository_impl import SQLAlchemyUserRepository

router = APIRouter()


def get_user_repository(db: AsyncSession = Depends(get_db)) -> SQLAlchemyUserRepository:
    """Dependency to get user repository."""
    return SQLAlchemyUserRepository(db)


@router.post("/", response_model=UserDTO, status_code=status.HTTP_201_CREATED)
async def create_user(
    user_data: CreateUserDTO,
    repository: SQLAlchemyUserRepository = Depends(get_user_repository)
):
    """Create a new user."""
    use_case = CreateUserUseCase(repository)
    try:
        return await use_case.execute(user_data)
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))


@router.get("/{user_id}", response_model=UserDTO)
async def get_user(
    user_id: int,
    repository: SQLAlchemyUserRepository = Depends(get_user_repository)
):
    """Get a user by ID."""
    use_case = GetUserByIdUseCase(repository)
    user = await use_case.execute(user_id)
    
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")
    
    return user


@router.get("/", response_model=List[UserDTO])
async def get_users(
    skip: int = 0,
    limit: int = 100,
    repository: SQLAlchemyUserRepository = Depends(get_user_repository)
):
    """Get all users."""
    use_case = GetAllUsersUseCase(repository)
    return await use_case.execute({"skip": skip, "limit": limit})


@router.put("/{user_id}", response_model=UserDTO)
async def update_user(
    user_id: int,
    user_data: UpdateUserDTO,
    repository: SQLAlchemyUserRepository = Depends(get_user_repository)
):
    """Update a user."""
    use_case = UpdateUserUseCase(repository)
    user = await use_case.execute((user_id, user_data))
    
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")
    
    return user


@router.delete("/{user_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_user(
    user_id: int,
    repository: SQLAlchemyUserRepository = Depends(get_user_repository)
):
    """Delete a user."""
    use_case = DeleteUserUseCase(repository)
    deleted = await use_case.execute(user_id)
    
    if not deleted:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")
