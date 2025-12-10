# Hướng Dẫn Cài Đặt

## Yêu Cầu Hệ Thống

Trước khi bắt đầu, hãy đảm bảo máy tính của bạn đã cài đặt:

| Công cụ     | Phiên bản | Tải về                                                        |
| ----------- | --------- | ------------------------------------------------------------- |
| Git         | Mới nhất  | [git-scm.com](https://git-scm.com/downloads)                  |
| Python      | 3.10+     | [python.org](https://www.python.org/downloads/)               |
| Flutter SDK | Stable    | [flutter.dev](https://docs.flutter.dev/get-started/install)   |
| Docker      | Mới nhất  | [docker.com](https://www.docker.com/products/docker-desktop/) |

---

## Cài Đặt Backend

### Bước 1: Clone dự án

```bash
git clone https://github.com/CuongKenn/ICTU-OpenAgri.git
cd ICTU-OpenAgri/backend
```

### Bước 2: Tạo môi trường ảo

=== "Windows"

    ```powershell
    python -m venv venv
    venv\Scripts\activate
    ```

=== "macOS/Linux"

    ```bash
    python3 -m venv venv
    source venv/bin/activate
    ```

### Bước 3: Cài đặt thư viện

```bash
pip install -r requirements.txt
```

### Bước 4: Cấu hình biến môi trường

Tạo file `.env` trong thư mục `backend`:

```ini
PROJECT_NAME=ICTU-OpenAgri
ENVIRONMENT=development
SECRET_KEY=your-secret-key-change-in-production

# Copernicus (đăng ký tại dataspace.copernicus.eu)
COPERNICUS_USERNAME=your_email
COPERNICUS_PASSWORD=your_password

# Admin mặc định
ADMIN_EMAIL=admin@openagri.com
ADMIN_PASSWORD=admin123
```

### Bước 5: Khởi chạy Server

```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

!!! success "Thành công" - API: `http://localhost:8000` - Swagger UI: `http://localhost:8000/api/docs`

---

## Cài Đặt Frontend

### Bước 1: Di chuyển vào thư mục frontend

```bash
cd ../frontend
```

### Bước 2: Kiểm tra Flutter

```bash
flutter doctor
```

### Bước 3: Cài đặt packages

```bash
flutter pub get
```

### Bước 4: Chạy ứng dụng

```bash
flutter run
```

---

## Bước Tiếp Theo

- [Chạy với Docker](docker.md) - Cách nhanh nhất
- [Cấu hình](configuration.md) - Chi tiết biến môi trường
