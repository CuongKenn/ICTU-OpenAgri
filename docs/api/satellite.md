# Satellite API

API xử lý ảnh vệ tinh Sentinel-1/2 từ Copernicus Data Space.

---

## Endpoints

### Tải ảnh vệ tinh

```http
POST /api/v1/satellite/download
Authorization: Bearer <token>
```

**Request Body:**

```json
{
  "farm_id": 1,
  "collection": "SENTINEL-2",
  "start_date": "2024-01-01",
  "end_date": "2024-01-15",
  "cloud_cover_max": 20
}
```

**Response (202 Accepted):**

```json
{
  "task_id": "abc123",
  "status": "queued",
  "message": "Download task queued. Check status with GET /satellite/tasks/{task_id}"
}
```

---

### Tính NDVI

```http
POST /api/v1/satellite/ndvi
Authorization: Bearer <token>
```

**Request Body:**

```json
{
  "farm_id": 1,
  "satellite_image_id": 5
}
```

**Response (200 OK):**

```json
{
  "farm_id": 1,
  "satellite_image_id": 5,
  "ndvi_mean": 0.72,
  "ndvi_min": 0.45,
  "ndvi_max": 0.89,
  "ndvi_std": 0.08,
  "calculation_date": "2024-01-15T10:30:00Z",
  "vegetation_health": "good"
}
```

---

### Tính Soil Moisture

```http
POST /api/v1/satellite/soil-moisture
Authorization: Bearer <token>
```

**Request Body:**

```json
{
  "farm_id": 1,
  "sar_image_id": 3
}
```

!!! info "SAR Images"
Soil moisture được tính từ ảnh Sentinel-1 (SAR), không phải Sentinel-2 (quang học).

---

### Lấy dữ liệu vệ tinh của trang trại

```http
GET /api/v1/farms/{farm_id}/satellite-data
Authorization: Bearer <token>
```

**Query Parameters:**

| Parameter    | Type   | Default | Mô tả                            |
| ------------ | ------ | ------- | -------------------------------- |
| `start_date` | date   | -       | Lọc từ ngày                      |
| `end_date`   | date   | -       | Lọc đến ngày                     |
| `type`       | string | -       | Loại: `SENTINEL-1`, `SENTINEL-2` |

**Response (200 OK):**

```json
[
  {
    "id": 5,
    "farm_id": 1,
    "product_id": "S2A_MSIL2A_20240114T...",
    "collection": "SENTINEL-2",
    "acquisition_date": "2024-01-14",
    "cloud_cover": 15.2,
    "ndvi": 0.72,
    "ndvi_classification": "good",
    "file_path": "/output/S2A_MSIL2A_20240114T.../",
    "created_at": "2024-01-15T08:00:00Z"
  }
]
```

---

## NDVI Classification

| NDVI Range | Classification | Mô tả                        | Color          |
| ---------- | -------------- | ---------------------------- | -------------- |
| < 0.1      | `bare_soil`    | Đất trống, không có thực vật | 🟤 Brown       |
| 0.1 - 0.2  | `sparse`       | Thực vật rất thưa            | 🟡 Yellow      |
| 0.2 - 0.4  | `moderate`     | Thực vật trung bình          | 🟢 Light Green |
| 0.4 - 0.6  | `good`         | Thực vật khỏe mạnh           | 🌿 Green       |
| > 0.6      | `dense`        | Thực vật rất dày đặc         | 🌲 Dark Green  |

```python
def classify_ndvi(ndvi: float) -> str:
    if ndvi < 0.1:
        return "bare_soil"
    elif ndvi < 0.2:
        return "sparse"
    elif ndvi < 0.4:
        return "moderate"
    elif ndvi < 0.6:
        return "good"
    else:
        return "dense"
```

---

## Copernicus Data Space

### Đăng ký tài khoản

1. Truy cập [dataspace.copernicus.eu](https://dataspace.copernicus.eu/)
2. Đăng ký tài khoản miễn phí
3. Lấy thông tin đăng nhập cho API

### Cấu hình

```bash title=".env"
COPERNICUS_USERNAME=your_email@example.com
COPERNICUS_PASSWORD=your_password
```

### Sản phẩm hỗ trợ

| Collection | Mô tả         | Resolution | Ứng dụng         |
| ---------- | ------------- | ---------- | ---------------- |
| SENTINEL-2 | Ảnh quang học | 10-60m     | NDVI, land cover |
| SENTINEL-1 | SAR           | 10m        | Soil moisture    |

---

## Scheduler Commands

Chạy thủ công trong Docker:

```bash
# Đồng bộ ảnh Sentinel-2 mới
docker exec -it openagri_backend python -c "
from app.scheduler import scheduler
import asyncio
asyncio.run(scheduler.sync_sentinel2_images())
"

# Tính NDVI cho tất cả farms
docker exec -it openagri_backend python -c "
from app.scheduler import scheduler
import asyncio
asyncio.run(scheduler.calculate_all_ndvi())
"

# Tính Soil Moisture
docker exec -it openagri_backend python -c "
from app.scheduler import scheduler
import asyncio
asyncio.run(scheduler.calculate_all_soil_moisture())
"
```

---

## Flutter Integration

```dart title="lib/models/satellite_data.dart"
class SatelliteData {
  final int id;
  final int farmId;
  final String collection;
  final DateTime acquisitionDate;
  final double? ndvi;
  final String? ndviClassification;
  final double? cloudCover;

  Color get ndviColor {
    if (ndvi == null) return Colors.grey;
    if (ndvi! < 0.1) return Colors.brown;
    if (ndvi! < 0.2) return Colors.yellow;
    if (ndvi! < 0.4) return Colors.lightGreen;
    if (ndvi! < 0.6) return Colors.green;
    return Colors.green.shade900;
  }
}
```

```dart title="lib/widgets/ndvi_chart.dart"
class NdviChart extends StatelessWidget {
  final List<SatelliteData> data;

  @override
  Widget build(BuildContext context) {
    return SfCartesianChart(
      primaryXAxis: DateTimeAxis(),
      primaryYAxis: NumericAxis(minimum: 0, maximum: 1),
      series: <ChartSeries>[
        LineSeries<SatelliteData, DateTime>(
          dataSource: data,
          xValueMapper: (d, _) => d.acquisitionDate,
          yValueMapper: (d, _) => d.ndvi,
          markerSettings: MarkerSettings(isVisible: true),
        ),
      ],
    );
  }
}
```

---

## Output Folder Structure

```plaintext
output/
├── S2A_MSIL2A_20240114T031611_N0510_R118_T48PWS.SAFE/
│   ├── MTD_MSIL2A.xml
│   ├── GRANULE/
│   │   └── L2A_T48PWS_A044376_20240114T032233/
│   │       ├── MTD_TL.xml
│   │       └── IMG_DATA/
│   │           ├── R10m/
│   │           │   ├── T48PWS_20240114T031611_B02_10m.jp2  # Blue
│   │           │   ├── T48PWS_20240114T031611_B03_10m.jp2  # Green
│   │           │   ├── T48PWS_20240114T031611_B04_10m.jp2  # Red
│   │           │   └── T48PWS_20240114T031611_B08_10m.jp2  # NIR
│   │           ├── R20m/
│   │           └── R60m/
│   └── ...
└── S1A_IW_GRDH_1SDV_20240110T.../
    └── ...
```

---

## Bước Tiếp Theo

- [NGSI-LD Data Models](../data-models/ngsi-ld.md)
- [FIWARE Integration](../architecture/fiware.md)
