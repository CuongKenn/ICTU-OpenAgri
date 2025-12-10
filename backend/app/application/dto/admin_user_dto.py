# Copyright (c) 2025 CuongKenn and ICTU-OpenAgri Contributors
# Licensed under the MIT License. See LICENSE file in the project root for full license information.

"""
Admin User Data Transfer Objects.
"""
from typing import Optional, List
from datetime import datetime
from pydantic import BaseModel, EmailStr, ConfigDict
from app.application.dto.user_dto import UserDTO


class AdminUserListItemDTO(BaseModel):
    """DTO for user list item in admin panel."""
    model_config = ConfigDict(from_attributes=True)
    
    id: int
    email: EmailStr
    username: str
    full_name: Optional[str] = None
    is_active: bool
    is_superuser: bool
    created_at: datetime
    updated_at: datetime


class AdminUserListResponseDTO(BaseModel):
    """DTO for paginated user list response."""
    users: List[AdminUserListItemDTO]
    total: int
    page: int
    page_size: int
    total_pages: int


class AdminUserDetailDTO(BaseModel):
    """DTO for detailed user information in admin panel."""
    model_config = ConfigDict(from_attributes=True)
    
    id: int
    email: EmailStr
    username: str
    full_name: Optional[str] = None
    is_active: bool
    is_superuser: bool
    created_at: datetime
    updated_at: datetime


class UpdateUserStatusDTO(BaseModel):
    """DTO for updating user status."""
    is_active: bool


class AdminUserStatsDTO(BaseModel):
    """DTO for user statistics."""
    total_users: int
    active_users: int
    inactive_users: int
    superusers: int
