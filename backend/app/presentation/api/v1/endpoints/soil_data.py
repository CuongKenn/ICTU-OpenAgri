# Copyright (c) 2025 CuongKenn and ICTU-OpenAgri Contributors
# Licensed under the MIT License. See LICENSE file in the project root for full license information.

"""
Serve soil analysis mock data for 34 provinces (NGSI-LD format).
Data source: backend/data/vietnam_34_provinces_soil_ngsi_ld.json
"""
from pathlib import Path
from typing import Any, Dict, List

from fastapi import APIRouter, HTTPException

router = APIRouter()


DATA_FILE = Path(__file__).resolve().parents[5] / "data" / "vietnam_34_provinces_soil_ngsi_ld.json"


@router.get("/soil-data", tags=["soil-data"])
def get_soil_data() -> Dict[str, Any]:
    """
    Trả về toàn bộ dữ liệu đất (34 tỉnh thành) ở định dạng NGSI-LD.
    """
    if not DATA_FILE.exists():
        raise HTTPException(status_code=404, detail="Soil data file not found")

    try:
        import json

        with DATA_FILE.open("r", encoding="utf-8") as f:
            payload = json.load(f)
        entities: List[Dict[str, Any]] = payload.get("entities", [])
        return {"count": len(entities), "entities": entities}
    except Exception as exc:  # pragma: no cover - defensive
        raise HTTPException(status_code=500, detail=f"Failed to read soil data: {exc}")

