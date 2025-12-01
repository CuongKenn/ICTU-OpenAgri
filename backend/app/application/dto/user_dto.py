# Copyright (c) 2025 CuongKenn and ICTU-OpenAgri Contributors
# Licensed under the MIT License. See LICENSE file in the project root for full license information.

"""
User Data Transfer Objects.
"""
from typing import Optional
from datetime import datetime
from pydantic import BaseModel, EmailStr, ConfigDict
from app.domain.entities.user import User


class CreateUserDTO(BaseModel):
    """DTO for creating a user."""
    email: EmailStr
    username: str
    password: str
    full_name: Optional[str] = None


class UpdateUserDTO(BaseModel):
    """DTO for updating a user."""
    email: Optional[EmailStr] = None
    username: Optional[str] = None
    full_name: Optional[str] = None
    is_active: Optional[bool] = None


class UserLoginDTO(BaseModel):
    """DTO for user login."""
    email: EmailStr
    password: str


class ChangePasswordDTO(BaseModel):
    """DTO for changing password."""
    current_password: str
    new_password: str


class TokenDTO(BaseModel):
    """DTO for token response."""
    access_token: str
    token_type: str


class UserDTO(BaseModel):
    """DTO for user response."""
    model_config = ConfigDict(from_attributes=True)
    
    id: int
    email: EmailStr
    username: str
    full_name: Optional[str] = None
    is_active: bool
    is_superuser: bool
    created_at: datetime
    updated_at: datetime
    
    @classmethod
    def from_entity(cls, user: User) -> "UserDTO":
        """Create DTO from entity."""
        return cls(
            id=user.id,
            email=user.email,
            username=user.username,
            full_name=user.full_name,
            is_active=user.is_active,
            is_superuser=user.is_superuser,
            created_at=user.created_at,
            updated_at=user.updated_at
        )
