# ICTU-OpenAgri

## Nền Tảng Nông Nghiệp Thông Minh

![Project Status](https://img.shields.io/badge/status-active-success.svg)
![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Python](https://img.shields.io/badge/python-3.10+-blue.svg)
![Flutter](https://img.shields.io/badge/flutter-3.0+-02569B.svg)

**ICTU-OpenAgri** là một nền tảng nông nghiệp số toàn diện, kết hợp sức mạnh của **Trí tuệ nhân tạo (AI)**, **Công nghệ viễn thám (Remote Sensing)**, **Bản đồ số (GIS)** và **FIWARE IoT Platform** để cung cấp giải pháp canh tác thông minh cho người nông dân và nhà quản lý.

---

## 🌟 Tính Năng Chính

<div class="grid cards" markdown>

- :satellite:{ .lg .middle } **Giám Sát Vệ Tinh**

  ***

  Phân tích NDVI và độ ẩm đất từ ảnh vệ tinh Sentinel-1/2

- :bug:{ .lg .middle } **Chẩn Đoán Sâu Bệnh**

  ***

  AI nhận diện bệnh cây trồng qua ảnh chụp lá

- :cloud:{ .lg .middle } **Dự Báo Thời Tiết**

  ***

  Thông tin thời tiết nông vụ từ Open-Meteo API

- :link:{ .lg .middle } **FIWARE IoT Platform**

  ***

  Dữ liệu chuẩn NGSI-LD, tương thích Smart Data Models

</div>

---

## 🚀 Bắt Đầu Nhanh

=== "Docker (Khuyên dùng)"

    ```bash
    git clone https://github.com/CuongKenn/ICTU-OpenAgri.git
    cd ICTU-OpenAgri
    docker-compose up --build
    ```

=== "Thủ công"

    ```bash
    # Backend
    cd backend
    pip install -r requirements.txt
    uvicorn app.main:app --reload

    # Frontend
    cd frontend
    flutter pub get
    flutter run
    ```

---

## 📚 Tài Liệu

| Phần                                       | Mô tả                       |
| ------------------------------------------ | --------------------------- |
| [Cài đặt](getting-started/installation.md) | Hướng dẫn cài đặt chi tiết  |
| [Kiến trúc](architecture/overview.md)      | Kiến trúc hệ thống C4 Model |
| [API Reference](api/authentication.md)     | Tài liệu API endpoints      |
| [NGSI-LD](data-models/ngsi-ld.md)          | Mô hình dữ liệu chuẩn       |

---

## 🏗️ Công Nghệ

- **Backend**: FastAPI, SQLAlchemy, TensorFlow
- **Frontend**: Flutter, Provider
- **FIWARE**: Orion-LD, QuantumLeap, CrateDB
- **Data**: NGSI-LD, Smart Data Models

---

## 📄 License

Dự án này được phân phối dưới giấy phép [MIT License](https://github.com/CuongKenn/ICTU-OpenAgri/blob/main/LICENSE).
