# Copyright (c) 2025 CuongKenn and ICTU-OpenAgri Contributors
# Licensed under the MIT License. See LICENSE file in the project root for full license information.

"""
SQLAlchemy User repository implementation.
"""
from typing import Optional, List
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.domain.entities.user import User
from app.domain.repositories.user_repository import UserRepository
from app.infrastructure.database.models.user_model import UserModel


class SQLAlchemyUserRepository(UserRepository):
    """SQLAlchemy implementation of UserRepository."""
    
    def __init__(self, session: AsyncSession):
        self.session = session
    
    def _to_entity(self, model: UserModel) -> User:
        """Convert database model to domain entity."""
        return User(
            id=model.id,
            email=model.email,
            username=model.username,
            hashed_password=model.hashed_password,
            full_name=model.full_name,
            is_active=model.is_active,
            is_superuser=model.is_superuser,
            created_at=model.created_at,
            updated_at=model.updated_at
        )
    
    def _to_model(self, entity: User) -> UserModel:
        """Convert domain entity to database model."""
        return UserModel(
            id=entity.id,
            email=entity.email,
            username=entity.username,
            hashed_password=entity.hashed_password,
            full_name=entity.full_name,
            is_active=entity.is_active,
            is_superuser=entity.is_superuser,
            created_at=entity.created_at,
            updated_at=entity.updated_at
        )
    
    async def create(self, entity: User) -> User:
        """Create a new user."""
        model = self._to_model(entity)
        self.session.add(model)
        await self.session.flush()
        await self.session.refresh(model)
        return self._to_entity(model)
    
    async def get_by_id(self, id: int) -> Optional[User]:
        """Get user by ID."""
        result = await self.session.execute(
            select(UserModel).where(UserModel.id == id)
        )
        model = result.scalar_one_or_none()
        return self._to_entity(model) if model else None
    
    async def get_all(self, skip: int = 0, limit: int = 100) -> List[User]:
        """Get all users with pagination."""
        result = await self.session.execute(
            select(UserModel).offset(skip).limit(limit)
        )
        models = result.scalars().all()
        return [self._to_entity(model) for model in models]
    
    async def update(self, id: int, entity: User) -> Optional[User]:
        """Update a user."""
        result = await self.session.execute(
            select(UserModel).where(UserModel.id == id)
        )
        model = result.scalar_one_or_none()
        
        if not model:
            return None
        
        model.email = entity.email
        model.username = entity.username
        model.hashed_password = entity.hashed_password
        model.full_name = entity.full_name
        model.is_active = entity.is_active
        model.is_superuser = entity.is_superuser
        
        await self.session.flush()
        await self.session.refresh(model)
        return self._to_entity(model)
    
    async def delete(self, id: int) -> bool:
        """Delete a user."""
        result = await self.session.execute(
            select(UserModel).where(UserModel.id == id)
        )
        model = result.scalar_one_or_none()
        
        if not model:
            return False
        
        await self.session.delete(model)
        await self.session.flush()
        return True
    
    async def get_by_email(self, email: str) -> Optional[User]:
        """Get user by email."""
        result = await self.session.execute(
            select(UserModel).where(UserModel.email == email)
        )
        model = result.scalar_one_or_none()
        return self._to_entity(model) if model else None
    
    async def get_by_username(self, username: str) -> Optional[User]:
        """Get user by username."""
        result = await self.session.execute(
            select(UserModel).where(UserModel.username == username)
        )
        model = result.scalar_one_or_none()
        return self._to_entity(model) if model else None
