"""
DTO cho giá nông sản.
"""
from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime


class PricePoint(BaseModel):
    """Điểm giá tại một ngày cụ thể."""
    date: str  # YYYY-MM-DD
    price: float
    market: str


class CommodityPriceDTO(BaseModel):
    """DTO cho giá nông sản."""
    id: str
    name: str
    name_en: str
    unit: str
    category: str
    prices: List[PricePoint]
    current_price: Optional[float] = None
    price_change_24h: Optional[float] = None
    price_change_percent_24h: Optional[float] = None
    min_price: Optional[float] = None
    max_price: Optional[float] = None


class CommodityPriceListResponse(BaseModel):
    """Response cho danh sách giá nông sản."""
    commodities: List[CommodityPriceDTO]
    total: int
    last_updated: str


class CommodityPriceDetailResponse(BaseModel):
    """Response chi tiết cho một loại nông sản."""
    commodity: CommodityPriceDTO
    chart_data: List[dict]  # Format: [{"date": "2024-01-01", "price": 12500, "open": 12400, "high": 12600, "low": 12300, "close": 12500}]
    price_history: List[PricePoint]


class CommodityPriceRequest(BaseModel):
    """Request để lấy giá nông sản."""
    commodity_id: Optional[str] = None
    category: Optional[str] = None
    start_date: Optional[str] = None  # YYYY-MM-DD
    end_date: Optional[str] = None   # YYYY-MM-DD
    limit: Optional[int] = 100

