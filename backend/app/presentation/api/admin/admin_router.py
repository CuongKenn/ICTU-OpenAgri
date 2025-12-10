# Copyright (c) 2025 CuongKenn and ICTU-OpenAgri Contributors
# Licensed under the MIT License. See LICENSE file in the project root for full license information.

"""
Admin API router.
"""
from fastapi import APIRouter
from app.presentation.api.admin.endpoints import admin_users, admin_farms

admin_router = APIRouter()

# Include admin user management endpoints
admin_router.include_router(admin_users.router, tags=["admin-users"])

# Include admin farm management endpoints
admin_router.include_router(admin_farms.router, tags=["admin-farms"])
