# Chạy với Docker

Docker là cách **nhanh nhất** để chạy toàn bộ hệ thống ICTU-OpenAgri với đầy đủ FIWARE components.

---

## Yêu Cầu

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) đã cài đặt
- RAM tối thiểu: **4GB** (khuyến nghị 8GB)

---

## Khởi Chạy

### Bước 1: Clone và chạy

```bash
git clone https://github.com/CuongKenn/ICTU-OpenAgri.git
cd ICTU-OpenAgri
docker-compose up --build
```

### Bước 2: Truy cập hệ thống

Sau khi khởi động thành công, các services sẽ sẵn sàng:

| Service              | URL                              | Mô tả             |
| -------------------- | -------------------------------- | ----------------- |
| Backend API          | `http://localhost:8000`          | FastAPI Server    |
| Swagger UI           | `http://localhost:8000/api/docs` | API Documentation |
| Frontend Web         | `http://localhost:3000`          | Flutter Web App   |
| Orion Context Broker | `http://localhost:1026`          | NGSI-LD API       |
| QuantumLeap          | `http://localhost:8668`          | Time-series API   |
| CrateDB Admin        | `http://localhost:4200`          | Database UI       |

---

## Kiểm Tra Services

### FIWARE Orion

```bash
curl http://localhost:1026/version
```

### QuantumLeap

```bash
curl http://localhost:8668/v2/version
```

---

## Các Lệnh Hữu Ích

```bash
# Chạy background
docker-compose up -d

# Xem logs
docker-compose logs -f backend

# Dừng tất cả
docker-compose down

# Dừng và xóa volumes
docker-compose down -v

# Rebuild một service
docker-compose up --build backend
```

---

## Xử Lý Lỗi

### CrateDB không start được

!!! warning "Lỗi vm.max_map_count"
`     max virtual memory areas vm.max_map_count [65530] is too low
    `

**Giải pháp trên Ubuntu/Linux:**

```bash
sudo sysctl -w vm.max_map_count=262144
echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf
```

**Giải pháp trên Windows (WSL2):**

```powershell
wsl -d docker-desktop -u root
sysctl -w vm.max_map_count=262144
```

---

## Bước Tiếp Theo

- [Cấu hình chi tiết](configuration.md)
- [Kiến trúc hệ thống](../architecture/overview.md)
