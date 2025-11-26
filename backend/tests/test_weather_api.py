"""
Tests for weather API endpoints.
"""
import pytest
from httpx import AsyncClient
from fastapi import FastAPI


@pytest.mark.asyncio
async def test_weather_forecast_valid_coordinates():
    """Test getting weather forecast with valid coordinates (Hanoi, Vietnam)."""
    from app.main import app
    
    async with AsyncClient(app=app, base_url="http://test") as client:
        response = await client.get(
            "/api/v1/weather/forecast",
            params={
                "latitude": 21.0285,
                "longitude": 105.8542,
                "location_name": "Hanoi"
            }
        )
        
        assert response.status_code == 200
        data = response.json()
        
        # Check location
        assert "location" in data
        assert data["location"]["latitude"] == 21.0285
        assert data["location"]["longitude"] == 105.8542
        
        # Check current weather
        assert "current" in data
        assert "temperature_2m" in data["current"]
        assert "relative_humidity_2m" in data["current"]
        assert "wind_speed_10m" in data["current"]
        
        # Check hourly data
        assert "hourly" in data
        assert isinstance(data["hourly"], list)
        assert len(data["hourly"]) > 0
        assert "temperature_2m" in data["hourly"][0]


@pytest.mark.asyncio
async def test_weather_forecast_invalid_latitude():
    """Test weather forecast with invalid latitude."""
    from app.main import app
    
    async with AsyncClient(app=app, base_url="http://test") as client:
        response = await client.get(
            "/api/v1/weather/forecast",
            params={
                "latitude": 100,  # Invalid: > 90
                "longitude": 105.8542
            }
        )
        
        assert response.status_code == 422  # Validation error


@pytest.mark.asyncio
async def test_location_search_valid_query():
    """Test searching locations with valid query."""
    from app.main import app
    
    async with AsyncClient(app=app, base_url="http://test") as client:
        response = await client.get(
            "/api/v1/weather/search",
            params={
                "query": "Hanoi",
                "limit": 5
            }
        )
        
        assert response.status_code == 200
        data = response.json()
        
        assert "results" in data
        assert "count" in data
        assert isinstance(data["results"], list)
        
        if data["count"] > 0:
            result = data["results"][0]
            assert "name" in result
            assert "latitude" in result
            assert "longitude" in result
            assert "country" in result


@pytest.mark.asyncio
async def test_location_search_vietnam():
    """Test searching for Vietnamese locations."""
    from app.main import app
    
    async with AsyncClient(app=app, base_url="http://test") as client:
        response = await client.get(
            "/api/v1/weather/search",
            params={
                "query": "Ho Chi Minh",
                "limit": 10
            }
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["count"] > 0


@pytest.mark.asyncio
async def test_location_search_empty_query():
    """Test search with empty query."""
    from app.main import app
    
    async with AsyncClient(app=app, base_url="http://test") as client:
        response = await client.get(
            "/api/v1/weather/search",
            params={
                "query": "",
                "limit": 10
            }
        )
        
        # Should fail validation
        assert response.status_code == 422


@pytest.mark.asyncio
async def test_reverse_geocode_valid_coordinates():
    """Test reverse geocoding with valid coordinates (Hanoi)."""
    from app.main import app
    
    async with AsyncClient(app=app, base_url="http://test") as client:
        response = await client.get(
            "/api/v1/weather/location/21.0285/105.8542"
        )
        
        assert response.status_code == 200
        data = response.json()
        
        assert "name" in data
        assert "country" in data
        assert "latitude" in data
        assert "longitude" in data
        assert data["latitude"] == 21.0285
        assert data["longitude"] == 105.8542


@pytest.mark.asyncio
async def test_reverse_geocode_vietnam():
    """Test reverse geocoding for Vietnam location (Ho Chi Minh City)."""
    from app.main import app
    
    async with AsyncClient(app=app, base_url="http://test") as client:
        response = await client.get(
            "/api/v1/weather/location/10.8231/106.6297"  # Ho Chi Minh City
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["country"].lower() == "vietnam" or "vietnam" in data["country"].lower()


@pytest.mark.asyncio
async def test_reverse_geocode_invalid_coordinates():
    """Test reverse geocoding with invalid latitude."""
    from app.main import app
    
    async with AsyncClient(app=app, base_url="http://test") as client:
        response = await client.get(
            "/api/v1/weather/location/100/105.8542"  # Invalid latitude
        )
        
        # Should fail validation
        assert response.status_code == 422


@pytest.mark.asyncio
async def test_forecast_with_hours_ahead():
    """Test forecast with custom hours ahead parameter."""
    from app.main import app
    
    async with AsyncClient(app=app, base_url="http://test") as client:
        response = await client.get(
            "/api/v1/weather/forecast",
            params={
                "latitude": 21.0285,
                "longitude": 105.8542,
                "hours_ahead": 48
            }
        )
        
        assert response.status_code == 200
        data = response.json()
        assert len(data["hourly"]) <= 48
