# Copyright (c) 2025 CuongKenn and ICTU-OpenAgri Contributors
# Licensed under the MIT License. See LICENSE file in the project root for full license information.

"""
User repository interface.
"""
from abc import abstractmethod
from typing import Optional
from app.domain.repositories.base import BaseRepository
from app.domain.entities.user import User


class UserRepository(BaseRepository[User]):
    """User repository interface."""
    
    @abstractmethod
    async def get_by_email(self, email: str) -> Optional[User]:
        """Get user by email."""
        pass
    
    @abstractmethod
    async def get_by_username(self, username: str) -> Optional[User]:
        """Get user by username."""
        pass
