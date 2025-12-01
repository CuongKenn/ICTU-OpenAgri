# Copyright (c) 2025 CuongKenn and ICTU-OpenAgri Contributors
# Licensed under the MIT License. See LICENSE file in the project root for full license information.

"""
Client để lấy dữ liệu giá nông sản.
Hiện tại đọc từ file JSON mock data, sau này có thể thay thế bằng API thật.
"""
import json
import os
from typing import List, Optional, Dict, Any
from datetime import datetime, timedelta
from app.application.dto.commodity_price_dto import CommodityPriceDTO, PricePoint
from app.infrastructure.config.settings import get_settings

settings = get_settings()

# Đường dẫn đến file mock data
# Tính từ: backend/app/infrastructure/external_services/commodity_price_client.py
# Lên 4 cấp: backend/
# Thêm data/mock_commodity_prices.json
BASE_DIR = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(__file__))))
MOCK_DATA_PATH = os.path.join(BASE_DIR, "data", "mock_commodity_prices.json")


def load_mock_data() -> Dict[str, Any]:
    """Load dữ liệu từ file JSON."""
    try:
        with open(MOCK_DATA_PATH, 'r', encoding='utf-8') as f:
            return json.load(f)
    except FileNotFoundError:
        raise RuntimeError(f"Mock data file not found at {MOCK_DATA_PATH}")
    except json.JSONDecodeError as e:
        raise RuntimeError(f"Error parsing JSON: {str(e)}")


def get_all_commodities(
    category: Optional[str] = None,
    start_date: Optional[str] = None,
    end_date: Optional[str] = None
) -> List[CommodityPriceDTO]:
    """
    Lấy tất cả các loại nông sản.
    
    Args:
        category: Lọc theo danh mục (lúa_gạo, cà_phê, etc.)
        start_date: Ngày bắt đầu (YYYY-MM-DD)
        end_date: Ngày kết thúc (YYYY-MM-DD)
    
    Returns:
        Danh sách CommodityPriceDTO
    """
    data = load_mock_data()
    commodities = []
    
    for item in data.get("commodities", []):
        # Lọc theo category nếu có
        if category and item.get("category") != category:
            continue
        
        # Lọc giá theo ngày nếu có
        prices = item.get("prices", [])
        if start_date or end_date:
            filtered_prices = []
            for price in prices:
                price_date = price.get("date")
                if start_date and price_date < start_date:
                    continue
                if end_date and price_date > end_date:
                    continue
                filtered_prices.append(price)
            prices = filtered_prices
        
        if not prices:
            continue
        
        # Tính toán các thống kê
        price_values = [p["price"] for p in prices]
        current_price = price_values[-1] if price_values else None
        min_price = min(price_values) if price_values else None
        max_price = max(price_values) if price_values else None
        
        # Tính thay đổi giá 24h (so sánh giá cuối với giá trước đó)
        price_change_24h = None
        price_change_percent_24h = None
        if len(price_values) >= 2:
            prev_price = price_values[-2]
            price_change_24h = current_price - prev_price
            price_change_percent_24h = (price_change_24h / prev_price) * 100 if prev_price > 0 else 0
        
        # Chuyển đổi prices sang PricePoint
        price_points = [
            PricePoint(date=p["date"], price=p["price"])
            for p in prices
        ]
        
        commodity = CommodityPriceDTO(
            id=item["id"],
            name=item["name"],
            name_en=item["name_en"],
            unit=item["unit"],
            category=item["category"],
            prices=price_points,
            current_price=current_price,
            price_change_24h=round(price_change_24h, 2) if price_change_24h is not None else None,
            price_change_percent_24h=round(price_change_percent_24h, 2) if price_change_percent_24h is not None else None,
            min_price=min_price,
            max_price=max_price
        )
        
        commodities.append(commodity)
    
    return commodities


def get_commodity_by_id(commodity_id: str) -> Optional[CommodityPriceDTO]:
    """
    Lấy thông tin chi tiết một loại nông sản theo ID.
    
    Args:
        commodity_id: ID của nông sản
    
    Returns:
        CommodityPriceDTO hoặc None nếu không tìm thấy
    """
    commodities = get_all_commodities()
    for commodity in commodities:
        if commodity.id == commodity_id:
            return commodity
    return None


def get_chart_data(commodity_id: str) -> List[Dict[str, Any]]:
    """
    Lấy dữ liệu biểu đồ cho một loại nông sản.
    Format phù hợp với biểu đồ candlestick/line chart.
    
    Args:
        commodity_id: ID của nông sản
    
    Returns:
        List of dict với format: [{"date": "2024-01-01", "price": 12500, "open": 12400, "high": 12600, "low": 12300, "close": 12500}]
    """
    commodity = get_commodity_by_id(commodity_id)
    if not commodity:
        return []
    
    chart_data = []
    prices = commodity.prices
    
    for i, price_point in enumerate(prices):
        price = price_point.price
        
        # Tính open, high, low, close
        # Với mock data, chúng ta sẽ tạo dữ liệu giả lập
        # Trong thực tế, API sẽ cung cấp đầy đủ OHLC data
        if i == 0:
            open_price = price
        else:
            open_price = prices[i-1].price
        
        # Tạo high và low dựa trên giá hiện tại (thêm biến động nhỏ)
        high = price * 1.02  # Cao hơn 2%
        low = price * 0.98   # Thấp hơn 2%
        close = price
        
        chart_data.append({
            "date": price_point.date,
            "price": price,
            "open": round(open_price, 2),
            "high": round(high, 2),
            "low": round(low, 2),
            "close": round(close, 2),
            "volume": 0  # Mock data không có volume
        })
    
    return chart_data


# TODO: Khi có API thật, thay thế các function trên bằng các API call
# Ví dụ:
# async def get_all_commodities_from_api(...) -> List[CommodityPriceDTO]:
#     async with httpx.AsyncClient() as client:
#         response = await client.get(f"{API_BASE_URL}/commodities", params={...})
#         return parse_response(response.json())

