# Farm API

API quản lý trang trại và vùng trồng.

---

## Endpoints

### Lấy danh sách trang trại

```http
GET /api/v1/farms
Authorization: Bearer <token>
```

**Query Parameters:**

| Parameter | Type | Default | Mô tả             |
| --------- | ---- | ------- | ----------------- |
| `skip`    | int  | 0       | Số bản ghi bỏ qua |
| `limit`   | int  | 100     | Số bản ghi tối đa |

**Response (200 OK):**

```json
[
  {
    "id": 1,
    "name": "Trang trại Đông Anh",
    "location": "Đông Anh, Hà Nội",
    "area": 5.5,
    "geometry": {
      "type": "Polygon",
      "coordinates": [
        [
          [105.8, 21.0],
          [105.9, 21.0],
          [105.9, 21.1],
          [105.8, 21.1],
          [105.8, 21.0]
        ]
      ]
    },
    "created_at": "2024-01-10T08:00:00Z",
    "updated_at": "2024-01-15T10:30:00Z"
  }
]
```

---

### Tạo trang trại mới

```http
POST /api/v1/farms
Authorization: Bearer <token>
```

**Request Body:**

```json
{
  "name": "Trang trại Đông Anh",
  "location": "Đông Anh, Hà Nội",
  "area": 5.5,
  "geometry": {
    "type": "Polygon",
    "coordinates": [
      [
        [105.8, 21.0],
        [105.9, 21.0],
        [105.9, 21.1],
        [105.8, 21.1],
        [105.8, 21.0]
      ]
    ]
  }
}
```

**Response (201 Created):**

```json
{
  "id": 1,
  "name": "Trang trại Đông Anh",
  "location": "Đông Anh, Hà Nội",
  "area": 5.5,
  "geometry": {...},
  "created_at": "2024-01-15T10:30:00Z"
}
```

---

### Lấy chi tiết trang trại

```http
GET /api/v1/farms/{farm_id}
Authorization: Bearer <token>
```

**Response (200 OK):**

```json
{
  "id": 1,
  "name": "Trang trại Đông Anh",
  "location": "Đông Anh, Hà Nội",
  "area": 5.5,
  "geometry": {...},
  "parcels": [
    {
      "id": 1,
      "name": "Lô A1",
      "crop_type": "Lúa",
      "area": 2.0
    }
  ],
  "satellite_data": [
    {
      "id": 1,
      "ndvi": 0.72,
      "acquisition_date": "2024-01-14"
    }
  ]
}
```

---

### Cập nhật trang trại

```http
PUT /api/v1/farms/{farm_id}
Authorization: Bearer <token>
```

**Request Body:**

```json
{
  "name": "Trang trại Đông Anh - Updated",
  "location": "Đông Anh, Hà Nội",
  "area": 6.0
}
```

---

### Xóa trang trại

```http
DELETE /api/v1/farms/{farm_id}
Authorization: Bearer <token>
```

**Response (204 No Content)**

!!! note "CASCADE DELETE"
Khi xóa trang trại, tất cả dữ liệu vệ tinh liên quan cũng sẽ bị xóa tự động.

---

## Parcel Endpoints

### Lấy danh sách vùng trồng

```http
GET /api/v1/farms/{farm_id}/parcels
Authorization: Bearer <token>
```

### Tạo vùng trồng

```http
POST /api/v1/farms/{farm_id}/parcels
Authorization: Bearer <token>
```

**Request Body:**

```json
{
  "name": "Lô A1",
  "crop_type": "Lúa",
  "area": 2.0,
  "planting_date": "2024-01-01",
  "geometry": {
    "type": "Polygon",
    "coordinates": [...]
  }
}
```

---

## GeoJSON Schema

Trang trại sử dụng GeoJSON để lưu trữ ranh giới:

```json
{
  "type": "Polygon",
  "coordinates": [
    [
      [longitude1, latitude1],
      [longitude2, latitude2],
      [longitude3, latitude3],
      [longitude4, latitude4],
      [longitude1, latitude1]
    ]
  ]
}
```

!!! tip "Lưu ý về GeoJSON" - Tọa độ theo định dạng `[longitude, latitude]` (không phải lat/lng) - Polygon phải đóng (điểm đầu = điểm cuối) - Tọa độ theo chiều kim đồng hồ

---

## Flutter Integration

```dart title="lib/models/farm.dart"
class Farm {
  final int id;
  final String name;
  final String? location;
  final double? area;
  final Map<String, dynamic>? geometry;

  Farm({
    required this.id,
    required this.name,
    this.location,
    this.area,
    this.geometry,
  });

  factory Farm.fromJson(Map<String, dynamic> json) {
    return Farm(
      id: json['id'],
      name: json['name'],
      location: json['location'],
      area: json['area']?.toDouble(),
      geometry: json['geometry'],
    );
  }
}
```

```dart title="lib/services/farm_service.dart"
class FarmService {
  final ApiService _api;

  Future<List<Farm>> getFarms() async {
    final response = await _api.get('/farms');
    return (response as List)
        .map((json) => Farm.fromJson(json))
        .toList();
  }

  Future<Farm> createFarm(FarmCreate data) async {
    final response = await _api.post('/farms', data: data.toJson());
    return Farm.fromJson(response);
  }
}
```

---

## Bước Tiếp Theo

- [Weather API](weather.md)
- [Satellite API](satellite.md)
