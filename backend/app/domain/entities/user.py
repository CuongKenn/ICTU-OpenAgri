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
    full_name: Optional[str] = None
    is_active: bool = True
    is_superuser: bool = False
