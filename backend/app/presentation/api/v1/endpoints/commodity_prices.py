"""
API endpoints cho giá nông sản.
"""
from fastapi import APIRouter, Query, HTTPException, Depends
from typing import Optional
from app.application.dto.commodity_price_dto import (
    CommodityPriceListResponse,
    CommodityPriceDetailResponse,
    CommodityPriceRequest
)
from app.application.use_cases.commodity_price_use_cases import (
    GetCommodityPricesUseCase,
    GetCommodityPriceDetailUseCase
)
from app.domain.entities.user import User
from app.presentation.deps import get_current_user

router = APIRouter()


@router.get("/", response_model=CommodityPriceListResponse)
async def get_commodity_prices(
    category: Optional[str] = Query(None, description="Lọc theo danh mục (lúa_gạo, cà_phê, hồ_tiêu, etc.)"),
    start_date: Optional[str] = Query(None, description="Ngày bắt đầu (YYYY-MM-DD)"),
    end_date: Optional[str] = Query(None, description="Ngày kết thúc (YYYY-MM-DD)"),
    limit: Optional[int] = Query(100, description="Số lượng tối đa"),
    current_user: User = Depends(get_current_user)
):
    """
    Lấy danh sách giá nông sản.
    
    - **category**: Lọc theo danh mục
    - **start_date**: Ngày bắt đầu
    - **end_date**: Ngày kết thúc
    - **limit**: Số lượng tối đa
    """
    request = CommodityPriceRequest(
        category=category,
        start_date=start_date,
        end_date=end_date,
        limit=limit
    )
    
    use_case = GetCommodityPricesUseCase()
    return use_case.execute(request)


@router.get("/{commodity_id}", response_model=CommodityPriceDetailResponse)
async def get_commodity_price_detail(
    commodity_id: str,
    current_user: User = Depends(get_current_user)
):
    """
    Lấy chi tiết giá một loại nông sản.
    
    Bao gồm:
    - Thông tin nông sản
    - Dữ liệu biểu đồ (OHLC format)
    - Lịch sử giá
    """
    use_case = GetCommodityPriceDetailUseCase()
    return use_case.execute(commodity_id)


@router.get("/categories/list")
async def get_categories(
    current_user: User = Depends(get_current_user)
):
    """
    Lấy danh sách các danh mục nông sản có sẵn.
    """
    from app.infrastructure.external_services.commodity_price_client import get_all_commodities
    
    commodities = get_all_commodities()
    categories = list(set([c.category for c in commodities]))
    
    return {
        "categories": categories,
        "total": len(categories)
    }

