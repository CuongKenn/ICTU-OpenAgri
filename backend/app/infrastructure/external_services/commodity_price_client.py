# Copyright (c) 2025 CuongKenn and ICTU-OpenAgri Contributors
# Licensed under the MIT License. See LICENSE file in the project root for full license information.

"""
Client để lấy dữ liệu giá nông sản.
Đọc từ file JSON theo chuẩn NGSI-LD, sau này có thể thay thế bằng API thật hoặc FIWARE.
"""
import json
import os
from typing import List, Optional, Dict, Any
from datetime import datetime, timedelta
from app.application.dto.commodity_price_dto import CommodityPriceDTO, PricePoint
from app.infrastructure.config.settings import get_settings

settings = get_settings()

# Đường dẫn đến file NGSI-LD data
# Tính từ: backend/app/infrastructure/external_services/commodity_price_client.py
# Lên 4 cấp: backend/
# Thêm data/vietnam_commodity_prices_ngsi_ld.json
BASE_DIR = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(__file__))))
NGSI_LD_DATA_PATH = os.path.join(BASE_DIR, "data", "vietnam_commodity_prices_ngsi_ld.json")

# Cache dữ liệu để tránh đọc file nhiều lần
_DATA_CACHE = None

def load_commodity_data() -> Dict[str, Any]:
    """Load dữ liệu từ file JSON NGSI-LD (có caching)."""
    global _DATA_CACHE
    if _DATA_CACHE is not None:
        return _DATA_CACHE

    try:
        with open(NGSI_LD_DATA_PATH, 'r', encoding='utf-8') as f:
            _DATA_CACHE = json.load(f)
            return _DATA_CACHE
    except FileNotFoundError:
        raise RuntimeError(f"NGSI-LD data file not found at {NGSI_LD_DATA_PATH}")
    except json.JSONDecodeError as e:
        raise RuntimeError(f"Error parsing JSON: {str(e)}")


def get_all_commodities(
    category: Optional[str] = None,
    start_date: Optional[str] = None,
    end_date: Optional[str] = None
) -> List[CommodityPriceDTO]:
    """
    Lấy tất cả các loại nông sản từ dữ liệu NGSI-LD.
    
    Args:
        category: Lọc theo danh mục (grains, beverages, spices, etc.)
        start_date: Ngày bắt đầu (YYYY-MM-DD)
        end_date: Ngày kết thúc (YYYY-MM-DD)
    
    Returns:
        Danh sách CommodityPriceDTO
    """
    data = load_commodity_data()
    commodities = []
    
    for item in data.get("commodities", []):
        # Extract data from NGSI-LD format
        item_category = item.get("category", {}).get("value", "")
        commodity_id = item.get("commodityId", {}).get("value", "")
        
        # Lọc theo category nếu có
        if category and item_category != category:
            continue
        
        # Extract price history from NGSI-LD format
        price_history = item.get("priceHistory", {}).get("value", [])
        
        # Convert NGSI-LD price format to simple format
        prices = []
        for price_entry in price_history:
            date_str = price_entry.get("dateObserved", "").split("T")[0]
            price_val = price_entry.get("price", 0)
            prices.append({"date": date_str, "price": price_val})
        
        # Lọc giá theo ngày nếu có
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
            id=commodity_id,
            name=item.get("name", {}).get("value", ""),
            name_en=item.get("alternateName", {}).get("value", ""),
            unit=item.get("priceUnit", {}).get("value", "VND/kg"),
            category=item_category,
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


# TODO: Khi có API thật hoặc FIWARE, thay thế các function trên bằng các API call
# Ví dụ:
# async def get_all_commodities_from_fiware(...) -> List[CommodityPriceDTO]:
#     async with httpx.AsyncClient() as client:
#         response = await client.get(f"{ORION_URL}/ngsi-ld/v1/entities", params={"type": "AgriCommodityPrice"})
#         return parse_ngsi_ld_response(response.json())

