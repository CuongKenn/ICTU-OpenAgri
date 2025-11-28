"""
Admin user management endpoints.
"""
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, status, Query

from app.application.dto.admin_user_dto import (
    AdminUserListResponseDTO,
    AdminUserDetailDTO,
    UpdateUserStatusDTO,
    AdminUserStatsDTO
)
from app.application.use_cases.admin_user_use_cases import (
    ListUsersUseCase,
    GetUserDetailUseCase,
    DeleteUserUseCase,
    UpdateUserStatusUseCase,
    GetUserStatsUseCase
)
from app.infrastructure.repositories.user_repository_impl import SQLAlchemyUserRepository
from app.presentation.deps import get_user_repository, get_current_user
from app.domain.entities.user import User

router = APIRouter()


@router.get("/users", response_model=AdminUserListResponseDTO)
async def list_users(
    page: int = Query(1, ge=1, description="Page number"),
    page_size: int = Query(10, ge=1, le=100, description="Items per page"),
    search: Optional[str] = Query(None, description="Search by email, username, or full name"),
    repository: SQLAlchemyUserRepository = Depends(get_user_repository),
    current_user: User = Depends(get_current_user)
):
    """
    List all users with pagination and optional search.
    
    Requires authentication.
    """
    use_case = ListUsersUseCase(repository)
    try:
        return await use_case.execute(page=page, page_size=page_size, search=search)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to retrieve users: {str(e)}"
        )


@router.get("/users/stats", response_model=AdminUserStatsDTO)
async def get_user_stats(
    repository: SQLAlchemyUserRepository = Depends(get_user_repository),
    current_user: User = Depends(get_current_user)
):
    """
    Get user statistics.
    
    Requires authentication.
    """
    use_case = GetUserStatsUseCase(repository)
    try:
        return await use_case.execute()
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to retrieve user statistics: {str(e)}"
        )


@router.get("/users/{user_id}", response_model=AdminUserDetailDTO)
async def get_user_detail(
    user_id: int,
    repository: SQLAlchemyUserRepository = Depends(get_user_repository),
    current_user: User = Depends(get_current_user)
):
    """
    Get detailed information about a specific user.
    
    Requires authentication.
    """
    use_case = GetUserDetailUseCase(repository)
    try:
        return await use_case.execute(user_id)
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to retrieve user details: {str(e)}"
        )


@router.delete("/users/{user_id}", status_code=status.HTTP_200_OK)
async def delete_user(
    user_id: int,
    repository: SQLAlchemyUserRepository = Depends(get_user_repository),
    current_user: User = Depends(get_current_user)
):
    """
    Delete a user from the system.
    
    Requires authentication.
    """
    # Prevent self-deletion
    if current_user.id == user_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cannot delete your own account"
        )
    
    use_case = DeleteUserUseCase(repository)
    try:
        await use_case.execute(user_id)
        return {"message": f"User {user_id} deleted successfully"}
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to delete user: {str(e)}"
        )


@router.patch("/users/{user_id}/status", response_model=AdminUserDetailDTO)
async def update_user_status(
    user_id: int,
    status_dto: UpdateUserStatusDTO,
    repository: SQLAlchemyUserRepository = Depends(get_user_repository),
    current_user: User = Depends(get_current_user)
):
    """
    Update user active status.
    
    Requires authentication.
    """
    # Prevent self-deactivation
    if current_user.id == user_id and not status_dto.is_active:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cannot deactivate your own account"
        )
    
    use_case = UpdateUserStatusUseCase(repository)
    try:
        return await use_case.execute(user_id, status_dto)
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to update user status: {str(e)}"
        )
