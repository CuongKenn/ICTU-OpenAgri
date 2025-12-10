# Smart Data Models

[Smart Data Models](https://smartdatamodels.org/) là bộ sưu tập các data model chuẩn hóa cho nhiều domain, bao gồm **AgriFood**.

---

## Smart Data Models là gì?

- **Chuẩn hóa** data models cho IoT và Smart Cities
- **Open source** và community-driven
- Được sử dụng bởi **FIWARE**, **IUDX**, **TM Forum**
- Hỗ trợ **NGSI-LD** và **NGSI-v2**

---

## AgriFood Domain

ICTU-OpenAgri sử dụng các Smart Data Models từ domain **AgriFood**:

| Data Model                                                                                               | Mô tả               | Trạng thái     |
| -------------------------------------------------------------------------------------------------------- | ------------------- | -------------- |
| [AgriParcel](https://github.com/smart-data-models/dataModel.Agrifood/tree/master/AgriParcel)             | Vùng trồng trọt     | ✅ Implemented |
| [AgriParcelRecord](https://github.com/smart-data-models/dataModel.Agrifood/tree/master/AgriParcelRecord) | Bản ghi hoạt động   | ✅ Implemented |
| [AgriCrop](https://github.com/smart-data-models/dataModel.Agrifood/tree/master/AgriCrop)                 | Loại cây trồng      | ⏳ Planned     |
| [AgriSoil](https://github.com/smart-data-models/dataModel.Agrifood/tree/master/AgriSoil)                 | Thổ nhưỡng          | ✅ Implemented |
| [AgriPest](https://github.com/smart-data-models/dataModel.Agrifood/tree/master/AgriPest)                 | Sâu bệnh            | ✅ Implemented |
| [WeatherObserved](https://github.com/smart-data-models/dataModel.Weather/tree/master/WeatherObserved)    | Quan trắc thời tiết | ✅ Implemented |

---

## AgriParcel

Mô tả một vùng trồng/thửa ruộng.

```json
{
  "@context": "https://smartdatamodels.org/context.jsonld",
  "id": "urn:ngsi-ld:AgriParcel:plot-001",
  "type": "AgriParcel",
  "name": {
    "type": "Property",
    "value": "Lô A1 - Lúa vụ Đông Xuân"
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
  "area": {
    "type": "Property",
    "value": 2.5,
    "unitCode": "ha"
  },
  "hasAgriCrop": {
    "type": "Relationship",
    "object": "urn:ngsi-ld:AgriCrop:rice"
  },
  "hasAgriSoil": {
    "type": "Relationship",
    "object": "urn:ngsi-ld:AgriSoil:alluvial"
  },
  "dateCreated": {
    "type": "Property",
    "value": "2024-01-01T00:00:00Z"
  }
}
```

### Thuộc tính chính

| Property      | Type         | Mô tả                                     |
| ------------- | ------------ | ----------------------------------------- |
| `name`        | Property     | Tên vùng trồng                            |
| `location`    | GeoProperty  | Ranh giới (Polygon)                       |
| `area`        | Property     | Diện tích (ha)                            |
| `hasAgriCrop` | Relationship | Loại cây trồng                            |
| `hasAgriSoil` | Relationship | Loại đất                                  |
| `cropStatus`  | Property     | Trạng thái (sepisotion/growing/harvested) |

---

## AgriParcelRecord

Bản ghi hoạt động/quan trắc trên vùng trồng.

```json
{
  "@context": "https://smartdatamodels.org/context.jsonld",
  "id": "urn:ngsi-ld:AgriParcelRecord:plot-001-2024-01-15",
  "type": "AgriParcelRecord",
  "hasAgriParcel": {
    "type": "Relationship",
    "object": "urn:ngsi-ld:AgriParcel:plot-001"
  },
  "relatedSource": {
    "type": "Property",
    "value": "Sentinel-2 MSI"
  },
  "leafRelativeHumidity": {
    "type": "Property",
    "value": 0.72,
    "observedAt": "2024-01-15T10:00:00Z"
  },
  "soilMoistureVwc": {
    "type": "Property",
    "value": 0.35,
    "observedAt": "2024-01-15T10:00:00Z"
  },
  "description": {
    "type": "Property",
    "value": "NDVI and Soil Moisture from Sentinel-1/2"
  }
}
```

---

## WeatherObserved

Dữ liệu thời tiết quan trắc.

```json
{
  "@context": "https://smartdatamodels.org/context.jsonld",
  "id": "urn:ngsi-ld:WeatherObserved:hanoi-2024-01-15T14:00:00Z",
  "type": "WeatherObserved",
  "dateObserved": {
    "type": "Property",
    "value": "2024-01-15T14:00:00Z"
  },
  "location": {
    "type": "GeoProperty",
    "value": {
      "type": "Point",
      "coordinates": [105.8342, 21.0278]
    }
  },
  "temperature": {
    "type": "Property",
    "value": 25.3,
    "unitCode": "CEL"
  },
  "relativeHumidity": {
    "type": "Property",
    "value": 0.78
  },
  "atmosphericPressure": {
    "type": "Property",
    "value": 1013.25,
    "unitCode": "HPA"
  },
  "windSpeed": {
    "type": "Property",
    "value": 12.5,
    "unitCode": "KMH"
  },
  "windDirection": {
    "type": "Property",
    "value": 180,
    "unitCode": "DD"
  },
  "precipitation": {
    "type": "Property",
    "value": 0.0,
    "unitCode": "MMT"
  }
}
```

---

## AgriSoil

Thông tin thổ nhưỡng.

```json
{
  "@context": "https://smartdatamodels.org/context.jsonld",
  "id": "urn:ngsi-ld:AgriSoil:alluvial-red-river",
  "type": "AgriSoil",
  "name": {
    "type": "Property",
    "value": "Đất phù sa sông Hồng"
  },
  "description": {
    "type": "Property",
    "value": "Đất phù sa được bồi hàng năm"
  },
  "soilTextureType": {
    "type": "Property",
    "value": "Loamy"
  },
  "hasAgriProductType": {
    "type": "Relationship",
    "object": ["urn:ngsi-ld:AgriCrop:rice", "urn:ngsi-ld:AgriCrop:vegetables"]
  }
}
```

---

## AgriPest

Thông tin sâu bệnh.

```json
{
  "@context": "https://smartdatamodels.org/context.jsonld",
  "id": "urn:ngsi-ld:AgriPest:brown-planthopper",
  "type": "AgriPest",
  "name": {
    "type": "Property",
    "value": "Rầy nâu"
  },
  "scientificName": {
    "type": "Property",
    "value": "Nilaparvata lugens"
  },
  "description": {
    "type": "Property",
    "value": "Rầy nâu là loài gây hại nguy hiểm nhất cho lúa tại Việt Nam"
  },
  "hasAgriProductType": {
    "type": "Relationship",
    "object": "urn:ngsi-ld:AgriCrop:rice"
  }
}
```

---

## Dữ Liệu Mẫu

ICTU-OpenAgri cung cấp dữ liệu mẫu NGSI-LD trong thư mục `backend/data/`:

| File                                    | Mô tả                    |
| --------------------------------------- | ------------------------ |
| `vietnam_34_province_soil_ngsi_ld.json` | Thổ nhưỡng 34 tỉnh thành |
| `vietnam_commodity_prices_ngsi_ld.json` | Giá nông sản             |
| `vietnam_pest_ngsi_ld.json`             | Sâu bệnh phổ biến        |

### Import vào Orion-LD

```bash
# Import soil data
curl -X POST 'http://localhost:1026/ngsi-ld/v1/entityOperations/upsert' \
  -H 'Content-Type: application/ld+json' \
  -d @backend/data/vietnam_34_province_soil_ngsi_ld.json
```

---

## Validation

Kiểm tra entity theo schema:

```bash
# Cài đặt SDM validator
pip install pysmartdatamodels

# Validate entity
python -c "
from pysmartdatamodels import validate_entity
result = validate_entity('AgriParcel', entity_json)
print(result)
"
```

---

## Bước Tiếp Theo

- [NGSI-LD Overview](ngsi-ld.md)
- [FIWARE Integration](../architecture/fiware.md)
