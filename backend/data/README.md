# Data Directory - NGSI-LD Smart Data Models

Thư mục này chứa các file dữ liệu theo chuẩn **NGSI-LD** (Next Generation Service Interface - Linked Data) của ETSI, tương thích với [Smart Data Models](https://smartdatamodels.org/) cho lĩnh vực nông nghiệp (AgriFood).

## 📁 Danh sách File

| File                                    | Mô tả                                | Smart Data Model                                   |
| --------------------------------------- | ------------------------------------ | -------------------------------------------------- |
| `vietnam_pest_ngsi_ld.json`             | Dữ liệu sâu bệnh hại tại Việt Nam    | [AgriPest](https://smartdatamodels.org/)           |
| `vietnam_commodity_prices_ngsi_ld.json` | Giá nông sản Việt Nam                | [AgriCommodityPrice](https://smartdatamodels.org/) |
| `vietnam_34_province_soil_ngsi_ld.json` | Phân tích đất 34 tỉnh thành Việt Nam | [SoilAnalysis](https://smartdatamodels.org/)       |

## 🔗 NGSI-LD Context

Tất cả các entity đều sử dụng context chuẩn:

```json
{
  "@context": [
    "https://uri.etsi.org/ngsi-ld/v1/ngsi-ld-core-context.jsonld",
    "https://smartdatamodels.org/context.jsonld"
  ]
}
```

## 📊 Cấu trúc Entity

### AgriPest (Sâu bệnh)

```json
{
  "id": "urn:ngsi-ld:AgriPest:vietnam-pest-001",
  "type": "AgriPest",
  "name": { "type": "Property", "value": "Rầy nâu" },
  "scientificName": { "type": "Property", "value": "Nilaparvata lugens" },
  "affectedCrops": { "type": "Property", "value": ["Lúa"] },
  "location": {
    "type": "GeoProperty",
    "value": { "type": "Point", "coordinates": [106.0, 21.0] }
  }
}
```

### AgriCommodityPrice (Giá nông sản)

```json
{
  "id": "urn:ngsi-ld:AgriCommodityPrice:rice-st25-2025",
  "type": "AgriCommodityPrice",
  "commodityName": { "type": "Property", "value": "Gạo ST25" },
  "price": { "type": "Property", "value": 25000, "unitCode": "VND/kg" },
  "observedAt": { "type": "Property", "value": "2025-01-01T00:00:00Z" }
}
```

### SoilAnalysis (Phân tích đất)

```json
{
  "id": "urn:ngsi-ld:SoilAnalysis:Vietnam:HaNoi",
  "type": "SoilAnalysis",
  "provinceName": { "type": "Property", "value": "Hà Nội" },
  "pH": { "type": "Property", "value": 5.6, "unitCode": "pH" },
  "nitrogen": { "type": "Property", "value": 0.13, "unitCode": "g/kg" },
  "location": {
    "type": "GeoProperty",
    "value": { "type": "Point", "coordinates": [105.8342, 21.0278] }
  }
}
```

## 🔄 Tích hợp với FIWARE

Các file này có thể được đẩy trực tiếp lên **Orion Context Broker** qua NGSI-LD API:

```bash
# Đẩy entity lên Orion
curl -X POST 'http://localhost:1026/ngsi-ld/v1/entities' \
  -H 'Content-Type: application/ld+json' \
  -d @vietnam_pest_ngsi_ld.json
```

## 📚 Tài liệu tham khảo

- [NGSI-LD Specification](https://www.etsi.org/deliver/etsi_gs/CIM/001_099/009/01.06.01_60/gs_cim009v010601p.pdf)
- [Smart Data Models - AgriFood](https://smartdatamodels.org/index.php/themes/agrifood/)
- [FIWARE NGSI-LD Tutorial](https://fiware-tutorials.readthedocs.io/en/latest/linked-data/)

---
