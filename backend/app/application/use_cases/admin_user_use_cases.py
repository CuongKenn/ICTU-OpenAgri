"""
Admin user management use cases.
"""
from typing import Optional
from math import ceil
from sqlalchemy import select, func
from app.application.use_cases.base import BaseUseCase
from app.domain.entities.user import User
from app.domain.repositories.user_repository import UserRepository
from app.application.dto.admin_user_dto import (
    AdminUserListResponseDTO,
    AdminUserListItemDTO,
    AdminUserDetailDTO,
    UpdateUserStatusDTO,
    AdminUserStatsDTO
)
from app.infrastructure.database.models.user_model import UserModel


class ListUsersUseCase(BaseUseCase):
    """Use case for listing all users with pagination."""
    
    def __init__(self, user_repository: UserRepository):
        self.user_repository = user_repository
    
    async def execute(
        self, 
        page: int = 1, 
        page_size: int = 10,
        search: Optional[str] = None
    ) -> AdminUserListResponseDTO:
        """
        List all users with pagination and optional search.
        
        Args:
            page: Page number (1-indexed)
            page_size: Number of items per page
            search: Optional search query for email, username, or full_name
        """
        skip = (page - 1) * page_size
        
        # Get session from repository
        session = self.user_repository.session
        
        # Build query
        query = select(UserModel)
        
        # Add search filter if provided
        if search:
            search_filter = f"%{search}%"
            query = query.where(
                (UserModel.email.ilike(search_filter)) |
                (UserModel.username.ilike(search_filter)) |
                (UserModel.full_name.ilike(search_filter))
            )
        
        # Get total count
        count_query = select(func.count()).select_from(query.subquery())
        total_result = await session.execute(count_query)
        total = total_result.scalar()
        
        # Get paginated results
        query = query.offset(skip).limit(page_size).order_by(UserModel.created_at.desc())
        result = await session.execute(query)
        users = result.scalars().all()
        
        # Convert to DTOs
        user_dtos = [
            AdminUserListItemDTO.model_validate(user) for user in users
        ]
        
        total_pages = ceil(total / page_size) if total > 0 else 0
        
        return AdminUserListResponseDTO(
            users=user_dtos,
            total=total,
            page=page,
            page_size=page_size,
            total_pages=total_pages
        )


class GetUserDetailUseCase(BaseUseCase):
    """Use case for getting detailed user information."""
    
    def __init__(self, user_repository: UserRepository):
        self.user_repository = user_repository
    
    async def execute(self, user_id: int) -> AdminUserDetailDTO:
        """Get detailed information about a specific user."""
        user = await self.user_repository.get_by_id(user_id)
        
        if not user:
            raise ValueError(f"User with ID {user_id} not found")
        
        return AdminUserDetailDTO(
            id=user.id,
            email=user.email,
            username=user.username,
            full_name=user.full_name,
            is_active=user.is_active,
            is_superuser=user.is_superuser,
            created_at=user.created_at,
            updated_at=user.updated_at
        )


class DeleteUserUseCase(BaseUseCase):
    """Use case for deleting a user."""
    
    def __init__(self, user_repository: UserRepository):
        self.user_repository = user_repository
    
    async def execute(self, user_id: int) -> bool:
        """
        Delete a user from the system.
        
        Args:
            user_id: ID of the user to delete
            
        Returns:
            True if user was deleted, raises ValueError if not found
        """
        # Check if user exists
        user = await self.user_repository.get_by_id(user_id)
        if not user:
            raise ValueError(f"User with ID {user_id} not found")
        
        # Delete user
        success = await self.user_repository.delete(user_id)
        
        if not success:
            raise ValueError(f"Failed to delete user with ID {user_id}")
        
        return True


class UpdateUserStatusUseCase(BaseUseCase):
    """Use case for updating user status (active/inactive)."""
    
    def __init__(self, user_repository: UserRepository):
        self.user_repository = user_repository
    
    async def execute(self, user_id: int, status_dto: UpdateUserStatusDTO) -> AdminUserDetailDTO:
        """
        Update user active status.
        
        Args:
            user_id: ID of the user to update
            status_dto: DTO containing new status
            
        Returns:
            Updated user details
        """
        user = await self.user_repository.get_by_id(user_id)
        
        if not user:
            raise ValueError(f"User with ID {user_id} not found")
        
        # Update status
        user.is_active = status_dto.is_active
        updated_user = await self.user_repository.update(user_id, user)
        
        if not updated_user:
            raise ValueError(f"Failed to update user with ID {user_id}")
        
        return AdminUserDetailDTO(
            id=updated_user.id,
            email=updated_user.email,
            username=updated_user.username,
            full_name=updated_user.full_name,
            is_active=updated_user.is_active,
            is_superuser=updated_user.is_superuser,
            created_at=updated_user.created_at,
            updated_at=updated_user.updated_at
        )


class GetUserStatsUseCase(BaseUseCase):
    """Use case for getting user statistics."""
    
    def __init__(self, user_repository: UserRepository):
        self.user_repository = user_repository
    
    async def execute(self) -> AdminUserStatsDTO:
        """Get statistics about users in the system."""
        session = self.user_repository.session
        
        # Total users
        total_query = select(func.count()).select_from(UserModel)
        total_result = await session.execute(total_query)
        total_users = total_result.scalar()
        
        # Active users
        active_query = select(func.count()).select_from(UserModel).where(UserModel.is_active == True)
        active_result = await session.execute(active_query)
        active_users = active_result.scalar()
        
        # Inactive users
        inactive_users = total_users - active_users
        
        # Superusers
        super_query = select(func.count()).select_from(UserModel).where(UserModel.is_superuser == True)
        super_result = await session.execute(super_query)
        superusers = super_result.scalar()
        
        return AdminUserStatsDTO(
            total_users=total_users,
            active_users=active_users,
            inactive_users=inactive_users,
            superusers=superusers
        )
