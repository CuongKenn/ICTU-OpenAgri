# Authentication API

API xác thực sử dụng **JWT (JSON Web Token)** cho việc authorize requests.

---

## Endpoints

### Đăng ký tài khoản

```http
POST /api/v1/auth/register
```

**Request Body:**

```json
{
  "email": "farmer@example.com",
  "password": "securepassword123",
  "full_name": "Nguyễn Văn A",
  "role": "farmer"
}
```

**Response (201 Created):**

```json
{
  "id": 1,
  "email": "farmer@example.com",
  "full_name": "Nguyễn Văn A",
  "role": "farmer",
  "created_at": "2024-01-15T10:30:00Z"
}
```

---

### Đăng nhập

```http
POST /api/v1/auth/login
```

**Request Body:**

```json
{
  "email": "farmer@example.com",
  "password": "securepassword123"
}
```

**Response (200 OK):**

```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "bearer",
  "expires_in": 86400,
  "user": {
    "id": 1,
    "email": "farmer@example.com",
    "full_name": "Nguyễn Văn A",
    "role": "farmer"
  }
}
```

---

### Lấy thông tin user hiện tại

```http
GET /api/v1/auth/me
Authorization: Bearer <access_token>
```

**Response (200 OK):**

```json
{
  "id": 1,
  "email": "farmer@example.com",
  "full_name": "Nguyễn Văn A",
  "role": "farmer",
  "created_at": "2024-01-15T10:30:00Z"
}
```

---

## JWT Token Structure

```json
{
  "sub": "1",
  "email": "farmer@example.com",
  "role": "farmer",
  "exp": 1705401000,
  "iat": 1705314600
}
```

| Field   | Mô tả                              |
| ------- | ---------------------------------- |
| `sub`   | User ID                            |
| `email` | Email người dùng                   |
| `role`  | Vai trò (farmer, admin)            |
| `exp`   | Thời gian hết hạn (Unix timestamp) |
| `iat`   | Thời gian tạo token                |

---

## Sử Dụng Token

### Trong HTTP Header

```http
GET /api/v1/farms
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### Trong Flutter

```dart title="lib/services/api_service.dart"
class ApiService {
  final Dio _dio = Dio();

  Future<void> setToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  Future<List<Farm>> getFarms() async {
    final response = await _dio.get('/api/v1/farms');
    return (response.data as List)
        .map((json) => Farm.fromJson(json))
        .toList();
  }
}
```

---

## Error Responses

### 401 Unauthorized

```json
{
  "detail": "Could not validate credentials"
}
```

### 403 Forbidden

```json
{
  "detail": "Not enough permissions"
}
```

### 422 Validation Error

```json
{
  "detail": [
    {
      "loc": ["body", "email"],
      "msg": "value is not a valid email address",
      "type": "value_error.email"
    }
  ]
}
```

---

## Roles & Permissions

| Role     | Permissions                                               |
| -------- | --------------------------------------------------------- |
| `farmer` | CRUD trang trại của mình, xem dữ liệu weather/satellite   |
| `admin`  | Tất cả quyền của farmer + quản lý users, xem tất cả farms |

---

## Security Best Practices

!!! warning "Bảo mật" - Luôn sử dụng HTTPS trong production - Không lưu token trong localStorage (dùng secure storage) - Token có thời hạn 24 giờ, cần refresh khi hết hạn - SECRET_KEY phải đủ dài (>= 32 ký tự) và ngẫu nhiên

---

## Bước Tiếp Theo

- [Farm API](farms.md)
- [Weather API](weather.md)
