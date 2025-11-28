# Admin Account Credentials

## Cài đặt Dependencies (Bước đầu tiên)

Trước khi tạo admin account, cần cài đặt dependencies:

```bash
cd backend
pip install -r requirements.txt
```

Hoặc chỉ cài đặt package cần thiết:

```bash
pip install passlib[bcrypt]
```

## Tạo Admin Account

### Cách 1: Sử dụng Script SQLite (Đơn giản)

```bash
cd backend
python create_admin_simple.py
```

### Cách 2: Sử dụng Script Async (Khuyến nghị)

```bash
cd backend
python create_admin.py
```

### Kiểm tra Admin Account

```bash
cd backend
python check_admin.py
```

## Thông tin đăng nhập mặc định

Sau khi chạy script thành công, bạn sẽ có tài khoản admin với thông tin:

- **Email**: `admin@openagri.com`
- **Username**: `admin`
- **Password**: `admin123`
- **Full Name**: `Administrator`
- **Role**: Superuser (Admin)

> ⚠️ **LƯU Ý BẢO MẬT**: 
> - Đổi mật khẩu ngay sau lần đăng nhập đầu tiên
> - Không sử dụng mật khẩu mặc định trong môi trường production
> - Script sẽ kiểm tra và không tạo lại nếu admin đã tồn tại

## Cách sử dụng

### 1. Truy cập Admin Panel (Frontend)

```dart
// Trong Flutter app
Navigator.pushNamed(context, '/admin');
```

Hoặc navigate trực tiếp đến route `/admin` trong ứng dụng.

### 2. Đăng nhập qua API

**Lấy Access Token**:

```bash
curl -X POST "http://localhost:8000/api/v1/users/login" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=admin@openagri.com&password=admin123"
```

**Response**:
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "bearer"
}
```

### 3. Sử dụng Admin Endpoints

**Lấy danh sách người dùng**:
```bash
curl -X GET "http://localhost:8000/api/v1/admin/users?page=1&page_size=10" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

**Lấy thống kê**:
```bash
curl -X GET "http://localhost:8000/api/v1/admin/users/stats" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

**Xóa người dùng**:
```bash
curl -X DELETE "http://localhost:8000/api/v1/admin/users/5" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

**Cập nhật trạng thái người dùng**:
```bash
curl -X PATCH "http://localhost:8000/api/v1/admin/users/5/status" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"is_active": false}'
```

## Đổi mật khẩu

Sử dụng endpoint change password:

```bash
curl -X POST "http://localhost:8000/api/v1/users/change-password" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "current_password": "admin123",
    "new_password": "your_new_secure_password"
  }'
```

## Troubleshooting

### Lỗi: "passlib not installed"

**Giải pháp**:
```bash
pip install passlib[bcrypt]
```

### Lỗi: "Users table does not exist"

**Giải pháp**: Chạy backend server trước để khởi tạo database:
```bash
cd backend
uvicorn app.main:app --reload
```

Sau đó dừng server (Ctrl+C) và chạy lại script tạo admin.

### Lỗi: "Admin user already exists"

Tài khoản admin đã tồn tại. Sử dụng thông tin đăng nhập ở trên hoặc reset database nếu cần.

## Scripts có sẵn

- `create_admin.py` - Script async sử dụng SQLAlchemy (khuyến nghị)
- `create_admin_simple.py` - Script SQLite đơn giản
- `check_admin.py` - Kiểm tra xem admin account đã tồn tại chưa
- `ADMIN_CREDENTIALS.md` - File hướng dẫn này
