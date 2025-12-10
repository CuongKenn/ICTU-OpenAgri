# Tổng Quan Kiến Trúc

Hệ thống ICTU-OpenAgri được thiết kế theo mô hình **C4 Model** kết hợp với **Clean Architecture** ở phía Backend.

---

## System Context (Level 1)

Mô tả sự tương tác giữa người dùng và các hệ thống bên ngoài.

```mermaid
graph TD
    classDef person fill:#08427b,stroke:#052e56,color:white;
    classDef system fill:#1168bd,stroke:#0b4884,color:white;
    classDef external fill:#999999,stroke:#6b6b6b,color:white;
    classDef fiware fill:#ff6600,stroke:#cc5200,color:white;

    Farmer("🧑‍🌾 Nông Dân"):::person
    Admin("👨‍💻 Quản Trị Viên"):::person

    System("📱 ICTU-OpenAgri System"):::system

    Copernicus("🛰️ Copernicus Data Space"):::external
    GBIF("🐞 GBIF API"):::external
    Weather("🌦️ Open-Meteo"):::external
    OSM("🗺️ OpenStreetMap"):::external
    SmartDataModels("📊 Smart Data Models"):::fiware

    Farmer -->|Quản lý vùng trồng| System
    Admin -->|Quản lý hệ thống| System
    System -->|Ảnh vệ tinh| Copernicus
    System -->|Dữ liệu sâu bệnh| GBIF
    System -->|Thời tiết| Weather
    System -->|Bản đồ| OSM
    System -.->|Chuẩn dữ liệu| SmartDataModels
```

---

## Container (Level 2)

Chi tiết các thành phần chính và công nghệ sử dụng.

```mermaid
graph TD
    classDef mobile fill:#2d882d,stroke:#1e5b1e,color:white;
    classDef api fill:#1168bd,stroke:#0b4884,color:white;
    classDef db fill:#2f2f2f,stroke:#000000,color:white;
    classDef fiware fill:#ff6600,stroke:#cc5200,color:white;

    User("👤 Người Dùng")

    subgraph "ICTU-OpenAgri System"
        MobileApp("📱 Mobile App<br>[Flutter]"):::mobile
        Backend("⚙️ Backend API<br>[FastAPI]"):::api
        Database("🗄️ Database<br>[SQLite/PostgreSQL]"):::db

        subgraph "FIWARE Stack"
            Orion("🔗 Orion-LD"):::fiware
            QuantumLeap("📈 QuantumLeap"):::fiware
            MongoDB("🍃 MongoDB"):::db
            CrateDB("📊 CrateDB"):::db
        end
    end

    User --> MobileApp
    MobileApp --> Backend
    Backend --> Database
    Backend --> Orion
    Orion --> MongoDB
    Orion --> QuantumLeap
    QuantumLeap --> CrateDB
```

---

## Component (Level 3)

Xem chi tiết tại: [Backend Architecture](backend.md)

---

## Công Nghệ Sử Dụng

### Backend

| Công nghệ   | Mục đích             |
| ----------- | -------------------- |
| FastAPI     | Web Framework        |
| SQLAlchemy  | ORM (AsyncIO)        |
| TensorFlow  | AI Disease Detection |
| Rasterio    | Xử lý ảnh vệ tinh    |
| APScheduler | Background Jobs      |

### Frontend

| Công nghệ   | Mục đích         |
| ----------- | ---------------- |
| Flutter     | UI Framework     |
| Provider    | State Management |
| Flutter Map | Bản đồ           |
| Dio         | HTTP Client      |

### FIWARE

| Công nghệ   | Mục đích               |
| ----------- | ---------------------- |
| Orion-LD    | NGSI-LD Context Broker |
| QuantumLeap | Time-series API        |
| CrateDB     | Time-series Database   |

---

## Bước Tiếp Theo

- [Backend Architecture](backend.md)
- [FIWARE Integration](fiware.md)
