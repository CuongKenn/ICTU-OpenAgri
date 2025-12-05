
import json
import os
from pathlib import Path

# Load mock data from JSON file
def load_mock_data():
    try:
        # Get the directory of the current file
        current_dir = Path(__file__).parent
        # Navigate to backend/data/vietnam_pest_mock_data.json
        # backend/app/infrastructure/external_services/ -> backend/data/
        json_path = current_dir.parent.parent.parent / "data" / "vietnam_pest_mock_data.json"
        
        with open(json_path, 'r', encoding='utf-8') as f:
            return json.load(f)
    except Exception as e:
        print(f"Error loading mock data: {e}")
        return {}

DONG_THAP_MOCK_DATA = load_mock_data()

# Export for use in backend
def get_mock_pest_data_for_vietnam(latitude: float, longitude: float, years_back: int = 10):
    """
    Get realistic mock data for Vietnam rice pests
    Only returns data if coordinates are in Vietnam (approximate check)
    """
    # Simple check if coordinates are in Vietnam
    if not (8.0 <= latitude <= 24.0 and 102.0 <= longitude <= 110.0):
        return None
    
    from datetime import datetime
    current_year = datetime.now().year
    start_year = current_year - years_back
    
    pest_summary = {}
    
    for pest_name, pest_info in DONG_THAP_MOCK_DATA["pest_data"].items():
        # Filter years based on years_back parameter
        yearly_data = {
            int(year): count 
            for year, count in pest_info["yearly_occurrences"].items()
            if start_year <= int(year) <= current_year
        }
        
        if yearly_data:
            pest_summary[pest_name] = {
                "pest_name": pest_name,
                "species_key": None,  
                "vietnamese_name": pest_info["common_name_vi"],
                "yearly_occurrences": yearly_data,
                "total_occurrences": sum(yearly_data.values()),
                "most_recent_year": max(yearly_data.keys())
            }
    
    # Generate warnings based on recent activity
    warnings = []
    for pest_name, data in pest_summary.items():
        pest_info = DONG_THAP_MOCK_DATA["pest_data"][pest_name]
        yearly = data["yearly_occurrences"]
        
        # Check recent years
        recent_years = [y for y in yearly.keys() if y >= current_year - 2]
        if recent_years and pest_info["severity"] in ["high", "medium"]:
            risk_level = "high" if pest_info["severity"] == "high" else "medium"
            warnings.append({
                "pest_name": pest_name,
                "vietnamese_name": pest_info["common_name_vi"],
                "risk_level": risk_level,
                "message": f"{pest_info['common_name_vi']} ({pest_name}) xuất hiện {sum(yearly[y] for y in recent_years)} lần trong 2 năm gần đây. {pest_info['damage_level']}.",
                "last_seen_year": max(recent_years),
                "occurrence_count": yearly[max(recent_years)]
            })
    
    return {
        "location": {
            "latitude": latitude,
            "longitude": longitude,
            "radius_km": 10.0
        },
        "pest_summary": pest_summary,
        "warnings": warnings,
        "checked_pests": list(DONG_THAP_MOCK_DATA["pest_data"].keys()),
        "total_occurrences": sum(data["total_occurrences"] for data in pest_summary.values()),
        "search_period": {
            "start_year": start_year,
            "end_year": current_year
        },
        "data_source": "Mock data based on Vietnam Plant Protection Department reports",
        "is_mock_data": True
    }

if __name__ == "__main__":
    # Test the function
    import json
    
    # Test with Dong Thap coordinates
    result = get_mock_pest_data_for_vietnam(10.4938, 105.6881, years_back=10)
    print(json.dumps(result, indent=2, ensure_ascii=False))
