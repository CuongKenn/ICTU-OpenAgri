# NGSI-LD Overview

NGSI-LD là chuẩn dữ liệu của ETSI dành cho IoT và Smart Cities, được ICTU-OpenAgri sử dụng để đảm bảo tính interoperability.

---

## NGSI-LD là gì?

**NGSI-LD** (Next Generation Service Interface - Linked Data) là:

- Chuẩn API do **ETSI** (European Telecommunications Standards Institute) phát triển
- Mở rộng của NGSI-v2 với khả năng Linked Data
- Sử dụng **JSON-LD** làm định dạng dữ liệu
- Hỗ trợ **semantic interoperability** qua `@context`

---

## Cấu Trúc Entity

```json
{
  "@context": [
    "https://uri.etsi.org/ngsi-ld/v1/ngsi-ld-core-context.jsonld",
    "https://smartdatamodels.org/context.jsonld"
  ],
  "id": "urn:ngsi-ld:AgriParcel:plot-001",
  "type": "AgriParcel",
  "name": {
    "type": "Property",
    "value": "Lô A1 - Đông Anh"
  },
  "location": {
    "type": "GeoProperty",
    "value": {
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
  },
  "hasAgriCrop": {
    "type": "Relationship",
    "object": "urn:ngsi-ld:AgriCrop:rice"
  },
  "dateCreated": {
    "type": "Property",
    "value": "2024-01-15T08:00:00Z"
  }
}
```

---

## Thành Phần Chính

### 1. Entity ID

URN (Uniform Resource Name) unique cho mỗi entity:

```
urn:ngsi-ld:<EntityType>:<identifier>
```

Ví dụ:

- `urn:ngsi-ld:AgriParcel:plot-001`
- `urn:ngsi-ld:WeatherObserved:hanoi-2024-01-15`

### 2. Entity Type

Loại entity theo Smart Data Models:

- `AgriParcel` - Vùng trồng
- `WeatherObserved` - Quan trắc thời tiết
- `AgriSoil` - Thổ nhưỡng

### 3. Property

Thuộc tính chứa giá trị:

```json
"temperature": {
  "type": "Property",
  "value": 25.3,
  "unitCode": "CEL",
  "observedAt": "2024-01-15T14:00:00Z"
}
```

### 4. GeoProperty

Thuộc tính địa lý (GeoJSON):

```json
"location": {
  "type": "GeoProperty",
  "value": {
    "type": "Point",
    "coordinates": [105.8342, 21.0278]
  }
}
```

### 5. Relationship

Liên kết đến entity khác:

```json
"hasAgriCrop": {
  "type": "Relationship",
  "object": "urn:ngsi-ld:AgriCrop:rice"
}
```

---

## @context

Context định nghĩa ngữ nghĩa của các thuộc tính:

```json
{
  "@context": [
    "https://uri.etsi.org/ngsi-ld/v1/ngsi-ld-core-context.jsonld",
    "https://smartdatamodels.org/context.jsonld",
    {
      "farm": "https://ictu.edu.vn/openagri/vocab#farm",
      "ndvi": "https://ictu.edu.vn/openagri/vocab#ndvi"
    }
  ]
}
```

---

## NGSI-LD API Operations

### Create Entity

```bash
curl -X POST 'http://localhost:1026/ngsi-ld/v1/entities' \
  -H 'Content-Type: application/ld+json' \
  -d '{
    "@context": "https://smartdatamodels.org/context.jsonld",
    "id": "urn:ngsi-ld:AgriParcel:plot-001",
    "type": "AgriParcel",
    "name": {"type": "Property", "value": "Lô A1"}
  }'
```

### Query Entities

```bash
# Lấy tất cả AgriParcel
curl 'http://localhost:1026/ngsi-ld/v1/entities?type=AgriParcel' \
  -H 'Accept: application/ld+json'

# Query theo thuộc tính
curl 'http://localhost:1026/ngsi-ld/v1/entities?type=WeatherObserved&q=temperature>25' \
  -H 'Accept: application/ld+json'

# Query theo vị trí (near point)
curl 'http://localhost:1026/ngsi-ld/v1/entities?type=AgriParcel&georel=near;maxDistance==1000&geometry=Point&coordinates=[105.8,21.0]' \
  -H 'Accept: application/ld+json'
```

### Update Entity

```bash
curl -X PATCH 'http://localhost:1026/ngsi-ld/v1/entities/urn:ngsi-ld:AgriParcel:plot-001/attrs' \
  -H 'Content-Type: application/json' \
  -d '{
    "area": {"type": "Property", "value": 3.5}
  }'
```

### Delete Entity

```bash
curl -X DELETE 'http://localhost:1026/ngsi-ld/v1/entities/urn:ngsi-ld:AgriParcel:plot-001'
```

---

## Subscriptions

Đăng ký nhận thông báo khi dữ liệu thay đổi:

```json
{
  "@context": "https://uri.etsi.org/ngsi-ld/v1/ngsi-ld-core-context.jsonld",
  "type": "Subscription",
  "entities": [{ "type": "WeatherObserved" }],
  "watchedAttributes": ["temperature", "relativeHumidity"],
  "notification": {
    "endpoint": {
      "uri": "http://quantumleap:8668/v2/notify",
      "accept": "application/json"
    }
  }
}
```

---

## So Sánh NGSI-v2 vs NGSI-LD

| Feature       | NGSI-v2 | NGSI-LD      |
| ------------- | ------- | ------------ |
| Format        | JSON    | JSON-LD      |
| Linked Data   | ❌      | ✅           |
| @context      | ❌      | ✅           |
| GeoJSON       | Limited | Full support |
| Relationships | attrs   | First-class  |
| Standard      | FIWARE  | ETSI         |

---

## Bước Tiếp Theo

- [Smart Data Models](smart-data.md)
- [FIWARE Integration](../architecture/fiware.md)
