# Copyright (c) 2025 CuongKenn and ICTU-OpenAgri Contributors
# Licensed under the MIT License. See LICENSE file in the project root for full license information.

"""
Use cases cho giá nông sản.
"""
from typing import List, Optional
from fastapi import HTTPException
from app.application.dto.commodity_price_dto import (
    CommodityPriceDTO,
    CommodityPriceListResponse,
    CommodityPriceDetailResponse,
    CommodityPriceRequest
)
from app.infrastructure.external_services.commodity_price_client import (
    get_all_commodities,
    get_commodity_by_id,
    get_chart_data
)


class GetCommodityPricesUseCase:
    """Use case để lấy danh sách giá nông sản."""
    
    def execute(self, request: CommodityPriceRequest) -> CommodityPriceListResponse:
        """
        Lấy danh sách giá nông sản.
        
        Args:
            request: CommodityPriceRequest với các filter
        
        Returns:
            CommodityPriceListResponse
        """
        try:
            commodities = get_all_commodities(
                category=request.category,
                start_date=request.start_date,
                end_date=request.end_date
            )
            
            # Giới hạn số lượng nếu có
            if request.limit:
                commodities = commodities[:request.limit]
            
            # Lấy thời gian cập nhật cuối
            from datetime import datetime
            last_updated = datetime.now().isoformat()
            
            return CommodityPriceListResponse(
                commodities=commodities,
                total=len(commodities),
                last_updated=last_updated
            )
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Error fetching commodity prices: {str(e)}")


class GetCommodityPriceDetailUseCase:
    """Use case để lấy chi tiết giá một loại nông sản."""
    
    def execute(self, commodity_id: str) -> CommodityPriceDetailResponse:
        """
        Lấy chi tiết giá một loại nông sản.
        
        Args:
            commodity_id: ID của nông sản
        
        Returns:
            CommodityPriceDetailResponse với chart data
        """
        try:
            commodity = get_commodity_by_id(commodity_id)
            
            if not commodity:
                raise HTTPException(
                    status_code=404,
                    detail=f"Commodity with id {commodity_id} not found"
                )
            
            # Lấy dữ liệu biểu đồ
            chart_data = get_chart_data(commodity_id)
            
            # Chuyển đổi prices thành price_history
            price_history = commodity.prices
            
            return CommodityPriceDetailResponse(
                commodity=commodity,
                chart_data=chart_data,
                price_history=price_history
            )
        except HTTPException:
            raise
        except Exception as e:
            raise HTTPException(
                status_code=500,
                detail=f"Error fetching commodity price detail: {str(e)}"
            )

