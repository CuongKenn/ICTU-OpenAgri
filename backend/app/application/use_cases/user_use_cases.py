"""
User-related use cases.
"""
from typing import Optional, List
from app.application.use_cases.base import BaseUseCase
from app.domain.entities.user import User
from app.domain.repositories.user_repository import UserRepository
from app.application.dto.user_dto import CreateUserDTO, UserDTO, UpdateUserDTO


class CreateUserUseCase(BaseUseCase[CreateUserDTO, UserDTO]):
    """Use case for creating a new user."""
    
    def __init__(self, user_repository: UserRepository):
        self.user_repository = user_repository
    
    async def execute(self, input_dto: CreateUserDTO) -> UserDTO:
        """Create a new user."""
        # Check if user already exists
        existing_user = await self.user_repository.get_by_email(input_dto.email)
        if existing_user:
            raise ValueError("User with this email already exists")
        
        # Create user entity
        user = User(
            email=input_dto.email,
            username=input_dto.username,
            full_name=input_dto.full_name,
            is_active=True,
            is_superuser=False
        )
        
        # Save to repository
        created_user = await self.user_repository.create(user)
        
        return UserDTO.from_entity(created_user)


class GetUserByIdUseCase(BaseUseCase[int, Optional[UserDTO]]):
    """Use case for getting a user by ID."""
    
    def __init__(self, user_repository: UserRepository):
        self.user_repository = user_repository
    
    async def execute(self, user_id: int) -> Optional[UserDTO]:
        """Get user by ID."""
        user = await self.user_repository.get_by_id(user_id)
        return UserDTO.from_entity(user) if user else None


class GetAllUsersUseCase(BaseUseCase[dict, List[UserDTO]]):
    """Use case for getting all users."""
    
    def __init__(self, user_repository: UserRepository):
        self.user_repository = user_repository
    
    async def execute(self, params: dict) -> List[UserDTO]:
        """Get all users with pagination."""
        skip = params.get('skip', 0)
        limit = params.get('limit', 100)
        
        users = await self.user_repository.get_all(skip=skip, limit=limit)
        return [UserDTO.from_entity(user) for user in users]


class UpdateUserUseCase(BaseUseCase[tuple[int, UpdateUserDTO], Optional[UserDTO]]):
    """Use case for updating a user."""
    
    def __init__(self, user_repository: UserRepository):
        self.user_repository = user_repository
    
    async def execute(self, input_data: tuple[int, UpdateUserDTO]) -> Optional[UserDTO]:
        """Update a user."""
        user_id, update_dto = input_data
        
        # Get existing user
        existing_user = await self.user_repository.get_by_id(user_id)
        if not existing_user:
            return None
        
        # Update fields
        if update_dto.email:
            existing_user.email = update_dto.email
        if update_dto.username:
            existing_user.username = update_dto.username
        if update_dto.full_name is not None:
            existing_user.full_name = update_dto.full_name
        if update_dto.is_active is not None:
            existing_user.is_active = update_dto.is_active
        
        # Save updates
        updated_user = await self.user_repository.update(user_id, existing_user)
        
        return UserDTO.from_entity(updated_user) if updated_user else None


class DeleteUserUseCase(BaseUseCase[int, bool]):
    """Use case for deleting a user."""
    
    def __init__(self, user_repository: UserRepository):
        self.user_repository = user_repository
    
    async def execute(self, user_id: int) -> bool:
        """Delete a user."""
        return await self.user_repository.delete(user_id)
