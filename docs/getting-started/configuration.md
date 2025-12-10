# Cấu Hình

Chi tiết các biến môi trường để cấu hình hệ thống ICTU-OpenAgri.

---

## Backend (.env)

Tạo file `.env` trong thư mục `backend/`:

```ini
# ==================== Cấu hình chung ====================
PROJECT_NAME=ICTU-OpenAgri
VERSION=1.0.0
ENVIRONMENT=development  # development | production

# ==================== API ====================
API_V1_STR=/api/v1
CORS_ORIGINS=["http://localhost:3000","http://localhost:5173"]

# ==================== Database ====================
DATABASE_URL=sqlite+aiosqlite:///./ictu_openagri.db
# Hoặc PostgreSQL:
# DATABASE_URL=postgresql+asyncpg://user:password@localhost:5432/openagri

# ==================== Bảo mật (JWT) ====================
SECRET_KEY=your-secret-key-change-in-production-please-use-a-strong-random-key
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30

# ==================== Copernicus Sentinel ====================
# Đăng ký tại: https://dataspace.copernicus.eu/
COPERNICUS_USERNAME=your_email@example.com
COPERNICUS_PASSWORD=your_password
OUTPUT_DIR=./output
MAX_PRODUCTS=20

# ==================== FIWARE ====================
FIWARE_ENABLED=true
ORION_URL=http://localhost:1026
QUANTUMLEAP_URL=http://localhost:8668

# ==================== Admin mặc định ====================
ADMIN_EMAIL=admin@openagri.com
ADMIN_PASSWORD=admin123
```

---

## Mô Tả Chi Tiết

### Cấu hình chung

| Biến           | Mặc định      | Mô tả           |
| -------------- | ------------- | --------------- |
| `PROJECT_NAME` | ICTU-OpenAgri | Tên dự án       |
| `ENVIRONMENT`  | development   | Môi trường chạy |

### Database

| Biến           | Mặc định | Mô tả                      |
| -------------- | -------- | -------------------------- |
| `DATABASE_URL` | sqlite   | Connection string database |

!!! tip "Production"
Nên sử dụng PostgreSQL cho production:
`     DATABASE_URL=postgresql+asyncpg://user:pass@host:5432/db
    `

### Bảo mật

| Biến                          | Mô tả                                     |
| ----------------------------- | ----------------------------------------- |
| `SECRET_KEY`                  | Khóa bí mật cho JWT (nên dài, ngẫu nhiên) |
| `ALGORITHM`                   | Thuật toán mã hóa (HS256)                 |
| `ACCESS_TOKEN_EXPIRE_MINUTES` | Thời gian hết hạn token                   |

!!! danger "Quan trọng"
**KHÔNG** sử dụng SECRET_KEY mặc định trong production!

    Tạo khóa ngẫu nhiên:
    ```bash
    python -c "import secrets; print(secrets.token_urlsafe(32))"
    ```

### Copernicus

| Biến                  | Mô tả                                     |
| --------------------- | ----------------------------------------- |
| `COPERNICUS_USERNAME` | Email đăng ký tại dataspace.copernicus.eu |
| `COPERNICUS_PASSWORD` | Mật khẩu tài khoản                        |
| `OUTPUT_DIR`          | Thư mục lưu ảnh vệ tinh                   |

### FIWARE

| Biến              | Mặc định              | Mô tả                    |
| ----------------- | --------------------- | ------------------------ |
| `FIWARE_ENABLED`  | true                  | Bật/tắt đồng bộ FIWARE   |
| `ORION_URL`       | http://localhost:1026 | URL Orion Context Broker |
| `QUANTUMLEAP_URL` | http://localhost:8668 | URL QuantumLeap          |

---

## Docker Compose Override

Để tùy chỉnh cấu hình Docker, tạo file `docker-compose.override.yml`:

```yaml
services:
  backend:
    environment:
      - ENVIRONMENT=production
      - SECRET_KEY=your-production-secret-key
```

---

## Bước Tiếp Theo

- [Kiến trúc hệ thống](../architecture/overview.md)
- [API Reference](../api/authentication.md)
