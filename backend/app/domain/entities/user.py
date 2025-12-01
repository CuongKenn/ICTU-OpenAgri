# Copyright (c) 2025 CuongKenn and ICTU-OpenAgri Contributors
# Licensed under the MIT License. See LICENSE file in the project root for full license information.

"""
User domain entity.
"""
from typing import Optional
from pydantic import EmailStr
from app.domain.entities.base import BaseEntity


class User(BaseEntity):
    """User domain entity."""
    
    email: EmailStr
    username: str
    hashed_password: str
    full_name: Optional[str] = None
    is_active: bool = True
    is_superuser: bool = False
