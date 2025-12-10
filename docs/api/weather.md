# Weather API

API thời tiết sử dụng [Open-Meteo](https://open-meteo.com/) - nguồn dữ liệu miễn phí và mở.

---

## Endpoints

### Lấy thời tiết hiện tại

```http
GET /api/v1/weather/current
Authorization: Bearer <token>
```

**Query Parameters:**

| Parameter   | Type  | Required | Mô tả   |
| ----------- | ----- | -------- | ------- |
| `latitude`  | float | ✅       | Vĩ độ   |
| `longitude` | float | ✅       | Kinh độ |

**Response (200 OK):**

```json
{
  "latitude": 21.0278,
  "longitude": 105.8342,
  "current": {
    "time": "2024-01-15T14:00:00Z",
    "temperature": 25.3,
    "apparent_temperature": 27.8,
    "relative_humidity": 78,
    "precipitation": 0.0,
    "cloud_cover": 45,
    "wind_speed": 12.5,
    "wind_direction": 180,
    "weather_code": 2
  }
}
```

---

### Lấy dự báo thời tiết

```http
GET /api/v1/weather/forecast
Authorization: Bearer <token>
```

**Query Parameters:**

| Parameter   | Type  | Required | Default | Mô tả                 |
| ----------- | ----- | -------- | ------- | --------------------- |
| `latitude`  | float | ✅       | -       | Vĩ độ                 |
| `longitude` | float | ✅       | -       | Kinh độ               |
| `days`      | int   | ❌       | 7       | Số ngày dự báo (1-16) |

**Response (200 OK):**

```json
{
  "latitude": 21.0278,
  "longitude": 105.8342,
  "daily": [
    {
      "date": "2024-01-15",
      "temperature_max": 28.5,
      "temperature_min": 18.2,
      "precipitation_sum": 0.0,
      "precipitation_probability_max": 10,
      "weather_code": 2,
      "sunrise": "06:32",
      "sunset": "17:45"
    },
    {
      "date": "2024-01-16",
      "temperature_max": 27.8,
      "temperature_min": 17.5,
      "precipitation_sum": 2.5,
      "precipitation_probability_max": 45,
      "weather_code": 61
    }
  ]
}
```

---

### Lấy dữ liệu lịch sử

```http
GET /api/v1/weather/historical
Authorization: Bearer <token>
```

**Query Parameters:**

| Parameter    | Type  | Required | Mô tả                      |
| ------------ | ----- | -------- | -------------------------- |
| `latitude`   | float | ✅       | Vĩ độ                      |
| `longitude`  | float | ✅       | Kinh độ                    |
| `start_date` | date  | ✅       | Ngày bắt đầu (YYYY-MM-DD)  |
| `end_date`   | date  | ✅       | Ngày kết thúc (YYYY-MM-DD) |

---

## Weather Codes

| Code  | Mô tả      | Icon |
| ----- | ---------- | ---- |
| 0     | Trời quang | ☀️   |
| 1-3   | Có mây     | ⛅   |
| 45-48 | Sương mù   | 🌫️   |
| 51-55 | Mưa phùn   | 🌧️   |
| 61-65 | Mưa        | 🌧️   |
| 71-77 | Tuyết      | ❄️   |
| 80-82 | Mưa rào    | 🌦️   |
| 95-99 | Giông bão  | ⛈️   |

---

## Thông số thời tiết

| Field                  | Unit | Mô tả                                                  |
| ---------------------- | ---- | ------------------------------------------------------ |
| `temperature`          | °C   | Nhiệt độ không khí                                     |
| `apparent_temperature` | °C   | Nhiệt độ cảm nhận (bao gồm ảnh hưởng của độ ẩm và gió) |
| `relative_humidity`    | %    | Độ ẩm tương đối                                        |
| `precipitation`        | mm   | Lượng mưa                                              |
| `wind_speed`           | km/h | Tốc độ gió                                             |
| `wind_direction`       | °    | Hướng gió (0° = Bắc, 90° = Đông)                       |
| `cloud_cover`          | %    | Độ che phủ mây                                         |
| `uv_index`             | -    | Chỉ số UV                                              |

---

## Flutter Integration

```dart title="lib/models/weather.dart"
class Weather {
  final double temperature;
  final double apparentTemperature;
  final int relativeHumidity;
  final double precipitation;
  final int weatherCode;
  final DateTime time;

  String get weatherDescription {
    switch (weatherCode) {
      case 0: return 'Trời quang';
      case 1:
      case 2:
      case 3: return 'Có mây';
      case 61:
      case 63:
      case 65: return 'Mưa';
      default: return 'Không xác định';
    }
  }

  String get icon {
    switch (weatherCode) {
      case 0: return '☀️';
      case 1:
      case 2:
      case 3: return '⛅';
      case 61:
      case 63:
      case 65: return '🌧️';
      default: return '🌤️';
    }
  }
}
```

```dart title="lib/widgets/weather_card.dart"
class WeatherCard extends StatelessWidget {
  final Weather weather;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(weather.icon, style: TextStyle(fontSize: 48)),
            Text('${weather.temperature}°C'),
            Text('Cảm giác như ${weather.apparentTemperature}°C'),
            Text('Độ ẩm: ${weather.relativeHumidity}%'),
          ],
        ),
      ),
    );
  }
}
```

---

## NGSI-LD WeatherObserved

Dữ liệu thời tiết được lưu vào Orion-LD theo Smart Data Model:

```json
{
  "@context": "https://smartdatamodels.org/context.jsonld",
  "id": "urn:ngsi-ld:WeatherObserved:hanoi-2024-01-15T14:00:00Z",
  "type": "WeatherObserved",
  "dateObserved": {
    "type": "Property",
    "value": "2024-01-15T14:00:00Z"
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
  "location": {
    "type": "GeoProperty",
    "value": {
      "type": "Point",
      "coordinates": [105.8342, 21.0278]
    }
  }
}
```

---

## Rate Limiting

!!! info "Open-Meteo Free Tier" - 10,000 requests/ngày - Không cần API key - Dữ liệu cập nhật mỗi giờ

---

## Bước Tiếp Theo

- [Satellite API](satellite.md)
- [NGSI-LD Data Models](../data-models/ngsi-ld.md)
