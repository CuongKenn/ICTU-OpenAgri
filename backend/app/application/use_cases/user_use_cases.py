"""
User-related use cases.
"""
from typing import Optional
from app.application.use_cases.base import BaseUseCase
from app.domain.entities.user import User
from app.domain.repositories.user_repository import UserRepository
from app.application.dto.user_dto import CreateUserDTO, UserDTO, UserLoginDTO, TokenDTO, ChangePasswordDTO
from app.infrastructure.security.jwt import get_password_hash, verify_password, create_access_token


class CreateUserUseCase(BaseUseCase[CreateUserDTO, UserDTO]):
    """Use case for creating a new user (Register)."""
    
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
            hashed_password=get_password_hash(input_dto.password),
            full_name=input_dto.full_name,
            is_active=True,
            is_superuser=False
        )
        
        # Save to repository
        created_user = await self.user_repository.create(user)
        
        return UserDTO.from_entity(created_user)


class LoginUserUseCase(BaseUseCase[UserLoginDTO, TokenDTO]):
    """Use case for user login."""
    
    def __init__(self, user_repository: UserRepository):
        self.user_repository = user_repository
    
    async def execute(self, input_dto: UserLoginDTO) -> TokenDTO:
        """Authenticate user and return token."""
        user = await self.user_repository.get_by_email(input_dto.email)
        if not user or not verify_password(input_dto.password, user.hashed_password):
            raise ValueError("Incorrect email or password")
        
        if not user.is_active:
            raise ValueError("Inactive user")
            
        access_token = create_access_token(subject=user.id)
        return TokenDTO(access_token=access_token, token_type="bearer")


class LogoutUserUseCase(BaseUseCase[None, bool]):
    """Use case for user logout."""
    
    async def execute(self, input_dto: None = None) -> bool:
        """
        Logout user.
        Since we use stateless JWT, we don't need to do anything on server side
        unless we implement a blacklist. For now, just return True.
        """
        return True


class ChangePasswordUseCase(BaseUseCase[ChangePasswordDTO, bool]):
    """Use case for changing user password."""
    
    def __init__(self, user_repository: UserRepository, user_id: int):
        self.user_repository = user_repository
        self.user_id = user_id
    
    async def execute(self, input_dto: ChangePasswordDTO) -> bool:
        """Change user password."""
        user = await self.user_repository.get_by_id(self.user_id)
        if not user:
            raise ValueError("User not found")
            
        if not verify_password(input_dto.current_password, user.hashed_password):
            raise ValueError("Incorrect current password")
            
        user.hashed_password = get_password_hash(input_dto.new_password)
        await self.user_repository.update(self.user_id, user)
        return True

