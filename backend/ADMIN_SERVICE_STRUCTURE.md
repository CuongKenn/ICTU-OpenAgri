# Cấu Trúc Admin Service

## Tổng Quan

Admin service đã được **tách riêng hoàn toàn** thành một folder độc lập trong backend, giúp bạn dễ dàng quản lý các chức năng admin.

## Cấu Trúc Folder

```
backend/app/
│
├── application/
│   ├── dto/
│   │   └── admin_user_dto.py          ✅ DTOs riêng cho admin
│   │
│   └── use_cases/
│       └── admin_user_use_cases.py    ✅ Use cases riêng cho admin
│
└── presentation/
    └── api/
        ├── admin/                      ✅ FOLDER ADMIN SERVICE RIÊNG
        │   ├── __init__.py
        │   ├── admin_router.py         # Router tổng hợp admin endpoints
        │   └── endpoints/
        │       ├── __init__.py
        │       └── admin_users.py      # Endpoints quản lý user
        │
        └── v1/
            └── router.py               # Import admin router vào đây
```

## Chi Tiết Các File

### 1. Admin DTOs (`app/application/dto/admin_user_dto.py`)

Chứa các Data Transfer Objects cho admin:
- `AdminUserListItemDTO` - Item trong danh sách user
- `AdminUserListResponseDTO` - Response với pagination
- `AdminUserDetailDTO` - Chi tiết user
- `UpdateUserStatusDTO` - Cập nhật trạng thái
- `AdminUserStatsDTO` - Thống kê user

### 2. Admin Use Cases (`app/application/use_cases/admin_user_use_cases.py`)

Chứa business logic cho admin:
- `ListUsersUseCase` - Lấy danh sách user (pagination + search)
- `GetUserDetailUseCase` - Xem chi tiết user
- `DeleteUserUseCase` - Xóa user
- `UpdateUserStatusUseCase` - Cập nhật trạng thái user
- `GetUserStatsUseCase` - Lấy thống kê user

### 3. Admin Endpoints (`app/presentation/api/admin/endpoints/admin_users.py`)

Chứa các API endpoints:
- `GET /admin/users` - Danh sách user
- `GET /admin/users/stats` - Thống kê
- `GET /admin/users/{user_id}` - Chi tiết user
- `DELETE /admin/users/{user_id}` - Xóa user
- `PATCH /admin/users/{user_id}/status` - Cập nhật trạng thái

### 4. Admin Router (`app/presentation/api/admin/admin_router.py`)

Router tổng hợp tất cả admin endpoints:
```python
from fastapi import APIRouter
from app.presentation.api.admin.endpoints import admin_users

admin_router = APIRouter()
admin_router.include_router(admin_users.router, tags=["admin-users"])
```

### 5. Main Router Integration (`app/presentation/api/v1/router.py`)

Admin router được mount vào main API:
```python
from app.presentation.api.admin.admin_router import admin_router
api_router.include_router(admin_router, prefix="/admin", tags=["admin"])
```

## Lợi Ích Của Cấu Trúc Này

### ✅ Tách Biệt Hoàn Toàn
- Admin service có folder riêng: `app/presentation/api/admin/`
- Dễ dàng tìm kiếm và quản lý code admin
- Không lẫn lộn với các API khác

### ✅ Mở Rộng Dễ Dàng
Khi cần thêm chức năng admin mới:

1. **Thêm endpoint mới** trong `admin/endpoints/`:
   ```
   admin/endpoints/
   ├── admin_users.py       # Quản lý user
   ├── admin_products.py    # Quản lý sản phẩm (mới)
   └── admin_reports.py     # Báo cáo (mới)
   ```

2. **Register trong admin_router.py**:
   ```python
   from app.presentation.api.admin.endpoints import (
       admin_users,
       admin_products,  # Mới
       admin_reports    # Mới
   )
   
   admin_router.include_router(admin_users.router, tags=["admin-users"])
   admin_router.include_router(admin_products.router, tags=["admin-products"])
   admin_router.include_router(admin_reports.router, tags=["admin-reports"])
   ```

### ✅ URL Structure Rõ Ràng
Tất cả admin endpoints đều có prefix `/admin`:
```
/api/v1/admin/users              # Admin user management
/api/v1/admin/users/stats        # Admin statistics
/api/v1/admin/users/{id}         # Admin user detail
/api/v1/admin/products           # Future: Product management
/api/v1/admin/reports            # Future: Reports
```

### ✅ Dễ Bảo Trì
- Tất cả code admin ở một chỗ
- Dễ thêm middleware riêng cho admin (RBAC, logging, etc.)
- Dễ test riêng admin features

## Ví Dụ Thêm Chức Năng Admin Mới

### Bước 1: Tạo DTO mới
```python
# app/application/dto/admin_product_dto.py
class AdminProductDTO(BaseModel):
    id: int
    name: str
    price: float
    # ...
```

### Bước 2: Tạo Use Case mới
```python
# app/application/use_cases/admin_product_use_cases.py
class ListProductsUseCase(BaseUseCase):
    async def execute(self):
        # Logic here
        pass
```

### Bước 3: Tạo Endpoint mới
```python
# app/presentation/api/admin/endpoints/admin_products.py
router = APIRouter()

@router.get("/products")
async def list_products():
    # Implementation
    pass
```

### Bước 4: Register vào Admin Router
```python
# app/presentation/api/admin/admin_router.py
from app.presentation.api.admin.endpoints import admin_users, admin_products

admin_router.include_router(admin_users.router, tags=["admin-users"])
admin_router.include_router(admin_products.router, tags=["admin-products"])
```

## API Documentation

Tất cả admin endpoints được tự động document trong Swagger UI:
- URL: `http://localhost:8000/api/docs`
- Tìm section "admin" hoặc "admin-users"

## Security

Tất cả admin endpoints đều yêu cầu authentication:
```python
@router.get("/users")
async def list_users(
    current_user: User = Depends(get_current_user)  # Authentication required
):
    pass
```

Trong tương lai có thể thêm admin role check:
```python
def get_current_admin_user(
    current_user: User = Depends(get_current_user)
) -> User:
    if not current_user.is_superuser:
        raise HTTPException(status_code=403, detail="Not authorized")
    return current_user
```

## Tóm Tắt

✅ **Admin service đã được tách riêng hoàn toàn**
✅ **Folder structure rõ ràng và dễ quản lý**
✅ **Dễ dàng mở rộng thêm chức năng admin**
✅ **URL structure nhất quán với prefix `/admin`**
✅ **Tất cả admin code ở một chỗ để dễ bảo trì**
