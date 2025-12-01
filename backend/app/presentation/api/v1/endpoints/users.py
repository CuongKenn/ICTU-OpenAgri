# Copyright (c) 2025 CuongKenn and ICTU-OpenAgri Contributors
# Licensed under the MIT License. See LICENSE file in the project root for full license information.

"""
User API endpoints.
"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from fastapi.security import OAuth2PasswordRequestForm

from app.application.dto.user_dto import CreateUserDTO, UserDTO, UserLoginDTO, TokenDTO, ChangePasswordDTO
from app.application.use_cases.user_use_cases import (
    CreateUserUseCase,
    LoginUserUseCase,
    LogoutUserUseCase,
    ChangePasswordUseCase
)
from app.infrastructure.repositories.user_repository_impl import SQLAlchemyUserRepository
from app.presentation.deps import get_user_repository, get_current_user
from app.domain.entities.user import User

router = APIRouter()


@router.post("/register", response_model=UserDTO, status_code=status.HTTP_201_CREATED)
async def register(
    user_data: CreateUserDTO,
    repository: SQLAlchemyUserRepository = Depends(get_user_repository)
):
    """Register a new user."""
    use_case = CreateUserUseCase(repository)
    try:
        return await use_case.execute(user_data)
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))


@router.post("/login", response_model=TokenDTO)
async def login(
    form_data: OAuth2PasswordRequestForm = Depends(),
    repository: SQLAlchemyUserRepository = Depends(get_user_repository)
):
    """
    Login user.
    Compatible with OAuth2PasswordRequestForm (username field = email).
    """
    use_case = LoginUserUseCase(repository)
    # OAuth2PasswordRequestForm puts email in 'username' field
    login_dto = UserLoginDTO(email=form_data.username, password=form_data.password)
    
    try:
        return await use_case.execute(login_dto)
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=str(e),
            headers={"WWW-Authenticate": "Bearer"},
        )


@router.post("/logout")
async def logout():
    """Logout user."""
    use_case = LogoutUserUseCase()
    await use_case.execute()
    return {"message": "Successfully logged out"}


@router.post("/change-password")
async def change_password(
    password_data: ChangePasswordDTO,
    current_user: User = Depends(get_current_user),
    repository: SQLAlchemyUserRepository = Depends(get_user_repository)
):
    """Change user password."""
    use_case = ChangePasswordUseCase(repository, current_user.id)
    try:
        await use_case.execute(password_data)
        return {"message": "Password changed successfully"}
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))


@router.get("/me", response_model=UserDTO)
async def read_users_me(
    current_user: User = Depends(get_current_user),
):
    """
    Get current user.
    """
    return current_user

