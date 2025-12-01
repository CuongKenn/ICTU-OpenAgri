# ICTU-OpenAgri - Hệ Thống Quản Lý Nông Nghiệp Thông Minh

![Project Status](https://img.shields.io/badge/status-active-success.svg)
![License](https://img.shields.io/badge/license-MIT-blue.svg)

**ICTU-OpenAgri** là một nền tảng toàn diện được thiết kế để hiện đại hóa quy trình quản lý nông nghiệp. Hệ thống kết hợp sức mạnh của công nghệ viễn thám (Satellite Remote Sensing) và bản đồ số để cung cấp cho người nông dân và nhà quản lý những công cụ đắc lực trong việc giám sát mùa màng, quản lý vùng trồng và ra quyết định dựa trên dữ liệu.

## 🌟 Tính Năng Nổi Bật

### 1. Quản Lý Vùng Trồng (Farm Management)

- **Số hóa bản đồ**: Cho phép người dùng vẽ và lưu trữ ranh giới vùng trồng trực tiếp trên bản đồ số (OpenStreetMap).
- **Thông tin chi tiết**: Quản lý thông tin về loại cây trồng, diện tích, ngày xuống giống và lịch sử canh tác.
- **Định vị GPS**: Tích hợp định vị thời gian thực để hỗ trợ khảo sát thực địa.

### 2. Giám Sát Vệ Tinh (Satellite Monitoring)

- **Tích hợp dữ liệu Sentinel**: Hệ thống có khả năng xử lý dữ liệu từ vệ tinh Sentinel-1 và Sentinel-2.
- **Chỉ số thực vật**: Tính toán và hiển thị các chỉ số sức khỏe cây trồng (như NDVI) để phát hiện sớm sâu bệnh hoặc thiếu nước.
- **Lịch sử ảnh**: Theo dõi sự thay đổi của vùng trồng theo thời gian.

### 3. Dashboard & Báo Cáo

- **Trực quan hóa dữ liệu**: Biểu đồ thống kê diện tích, năng suất và tình trạng mùa vụ (sử dụng `fl_chart`).
- **Báo cáo tổng quan**: Cung cấp cái nhìn toàn cảnh về hoạt động sản xuất nông nghiệp.

### 4. Bảo Mật & Hệ Thống

- **Xác thực an toàn**: Đăng nhập/Đăng ký bảo mật với JWT (JSON Web Token).
- **Kiến trúc hiện đại**:
  - **Backend**: Clean Architecture giúp hệ thống dễ bảo trì và mở rộng.
  - **Frontend**: Mô hình MVVM (Model-View-ViewModel) tách biệt logic và giao diện.

---

## 🛠️ Công Nghệ Sử Dụng

### Backend (Server)

- **Ngôn ngữ**: Python 3.10+
- **Framework**: [FastAPI](https://fastapi.tiangolo.com/) - Hiệu năng cao, dễ phát triển.
- **Cơ sở dữ liệu**:
  - ORM: [SQLAlchemy](https://www.sqlalchemy.org/) (AsyncIO).
  - Database: SQLite (Dev) / PostgreSQL (Production).
  - Migrations: Alembic.
- **Xử lý ảnh vệ tinh**: `rasterio`, `numpy`, `matplotlib`.
- **Bảo mật**: `python-jose` (JWT), `passlib` (Hashing).

### Frontend (Mobile App)

- **Framework**: [Flutter](https://flutter.dev/) (Dart).
- **State Management**: Provider.
- **Bản đồ**: `flutter_map`, `latlong2`, `geolocator`.
- **Networking**: `dio` (HTTP client mạnh mẽ).
- **UI/UX**: `google_fonts`, `fl_chart`, `cupertino_icons`.

---

## 🚀 Hướng Dẫn Cài Đặt & Chạy Dự Án

### Yêu cầu tiên quyết

- **Python**: 3.10 trở lên.
- **Flutter SDK**: Phiên bản mới nhất (Stable channel).
- **Git**: Để quản lý mã nguồn.

### 1. Thiết lập Backend

```bash
# 1. Di chuyển vào thư mục backend
cd backend

# 2. Tạo môi trường ảo (Virtual Environment)
python -m venv venv

# 3. Kích hoạt môi trường ảo
# Windows:
venv\Scripts\activate
# macOS/Linux:
source venv/bin/activate

# 4. Cài đặt các thư viện phụ thuộc
pip install -r requirements.txt

# 5. Cấu hình biến môi trường (Tùy chọn)
# Tạo file .env từ .env.example nếu có

# 6. Khởi chạy Server
uvicorn app.main:app --reload
```

_Server sẽ chạy tại: `http://127.0.0.1:8000`_
_Tài liệu API (Swagger UI): `http://127.0.0.1:8000/api/docs`_

### 2. Thiết lập Frontend

```bash
# 1. Di chuyển vào thư mục frontend
cd frontend

# 2. Tải các gói phụ thuộc
flutter pub get

# 3. Kiểm tra thiết bị kết nối (Máy ảo hoặc Máy thật)
flutter devices

# 4. Chạy ứng dụng
flutter run
```

### 3. Chạy bằng Docker (Khuyên dùng)

Nếu bạn muốn chạy toàn bộ hệ thống nhanh chóng mà không cần cài đặt môi trường thủ công, hãy sử dụng Docker.

**Yêu cầu:**

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) đã được cài đặt và đang chạy.

**Các bước thực hiện:**

1.  **Build và chạy container:**

    ```bash
    docker-compose up --build
    ```

    Lệnh này sẽ tự động build images cho cả Backend và Frontend, sau đó khởi chạy các container.

2.  **Truy cập ứng dụng:**
    - **Backend API**: `http://localhost:8000`
    - **API Docs**: `http://localhost:8000/api/docs`
    - **Frontend (Web)**: `http://localhost:3000` (Nếu bạn chạy bản web)

3.  **Dừng hệ thống:**
    Nhấn `Ctrl + C` trong terminal hoặc chạy lệnh:
    ```bash
    docker-compose down
    ```

---

## 📂 Cấu Trúc Dự Án

```
ICTU-OpenAgri/
├── backend/                # Mã nguồn Server (FastAPI)
│   ├── app/
│   │   ├── application/    # Business Logic (Use Cases, DTOs)
│   │   ├── domain/         # Entities, Interfaces (Core)
│   │   ├── infrastructure/ # Database, External Services
│   │   ├── presentation/   # API Endpoints
│   │   └── main.py         # Entry point
│   ├── data/               # Dữ liệu mẫu
│   └── output/             # Kết quả xử lý ảnh vệ tinh
│
├── frontend/               # Mã nguồn Mobile App (Flutter)
│   ├── lib/
│   │   ├── config/         # Cấu hình (Theme, Routes)
│   │   ├── models/         # Data Models
│   │   ├── screens/        # Màn hình UI (Home, Map, Dashboard)
│   │   ├── services/       # API Services
│   │   ├── viewmodels/     # Logic xử lý trạng thái (Provider)
│   │   ├── views/          # Widgets tái sử dụng
│   │   └── main.dart       # Entry point
│   └── pubspec.yaml        # Quản lý dependencies
│
└── README.md               # Tài liệu dự án
```

## 🤝 Đóng Góp (Contributing)

Chúng tôi rất hoan nghênh mọi đóng góp từ cộng đồng! Để đóng góp:

1.  **Fork** dự án này.
2.  Tạo nhánh tính năng mới (`git checkout -b feature/AmazingFeature`).
3.  Commit thay đổi của bạn (`git commit -m 'Add some AmazingFeature'`).
4.  Push lên nhánh (`git push origin feature/AmazingFeature`).
5.  Mở một **Pull Request**.

Vui lòng xem file `CONTRIBUTING.md` để biết thêm chi tiết quy tắc ứng xử.

## 🐛 Báo Lỗi (Bug Tracker)

Nếu bạn phát hiện lỗi hoặc muốn yêu cầu tính năng mới, vui lòng tạo issue tại:
[https://github.com/CuongKenn/ICTU-OpenAgri/issues](https://github.com/CuongKenn/ICTU-OpenAgri/issues)

## 📄 Giấy Phép (License)

Dự án này được phân phối dưới giấy phép **MIT License**. Xem file `LICENSE` để biết thêm chi tiết.

## 📞 Liên Hệ

- **Tác giả**: CuongKenn
- **GitHub**: [https://github.com/CuongKenn/ICTU-OpenAgri](https://github.com/CuongKenn/ICTU-OpenAgri)

---

_Dự án được phát triển với ❤️ cho nền nông nghiệp số._
