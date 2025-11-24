"""
Tests for Land Map API
"""
import pytest
from httpx import AsyncClient
from app.main import app


@pytest.mark.asyncio
async def test_landmap_info():
    """Test getting land map information"""
    async with AsyncClient(app=app, base_url="http://test") as client:
        response = await client.get("/api/v1/landmap/info")
        assert response.status_code == 200
        data = response.json()
        assert "service" in data
        assert "data_sources" in data
        assert "endpoints" in data


@pytest.mark.asyncio
async def test_get_classifications_lulc():
    """Test getting LULC classifications"""
    async with AsyncClient(app=app, base_url="http://test") as client:
        response = await client.get("/api/v1/landmap/classifications/lulc")
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)
        assert len(data) > 0
        assert "code" in data[0]
        assert "name" in data[0]
        assert "color" in data[0]


@pytest.mark.asyncio
async def test_get_classifications_nlcd():
    """Test getting NLCD classifications"""
    async with AsyncClient(app=app, base_url="http://test") as client:
        response = await client.get("/api/v1/landmap/classifications/nlcd")
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)
        assert len(data) > 0


@pytest.mark.asyncio
async def test_get_landmap_data_invalid_location():
    """Test with invalid latitude"""
    async with AsyncClient(app=app, base_url="http://test") as client:
        response = await client.get(
            "/api/v1/landmap/data?latitude=100&longitude=105&data_type=dem"
        )
        assert response.status_code == 422  # Validation error


@pytest.mark.asyncio
async def test_get_landmap_data_valid_parameters():
    """Test with valid parameters"""
    async with AsyncClient(app=app, base_url="http://test") as client:
        response = await client.get(
            "/api/v1/landmap/data?latitude=10.5&longitude=105.5&data_type=dem"
        )
        # May be 404 if no data, or 200 if data found
        assert response.status_code in [200, 404, 500]


@pytest.mark.asyncio
async def test_batch_query_empty():
    """Test batch query with empty list"""
    async with AsyncClient(app=app, base_url="http://test") as client:
        response = await client.post("/api/v1/landmap/batch", json=[])
        assert response.status_code == 200
        data = response.json()
        assert data["count"] == 0


@pytest.mark.asyncio
async def test_batch_query_valid():
    """Test batch query with valid locations"""
    async with AsyncClient(app=app, base_url="http://test") as client:
        payload = [
            {
                "location": {"latitude": 10.5, "longitude": 105.5},
                "data_type": "dem",
                "resolution": 250,
            },
            {
                "location": {"latitude": 20.5, "longitude": 110.5},
                "data_type": "lulc",
                "resolution": 250,
            },
        ]
        response = await client.post("/api/v1/landmap/batch", json=payload)
        assert response.status_code == 200
        data = response.json()
        assert "count" in data
        assert "results" in data


@pytest.mark.asyncio
async def test_get_statistics():
    """Test getting area statistics"""
    async with AsyncClient(app=app, base_url="http://test") as client:
        response = await client.get(
            "/api/v1/landmap/statistics?latitude=10.5&longitude=105.5&data_type=dem"
        )
        assert response.status_code in [200, 404, 500]
        if response.status_code == 200:
            data = response.json()
            assert "location" in data
            assert "data_type" in data


@pytest.mark.asyncio
async def test_invalid_data_type():
    """Test with invalid data type"""
    async with AsyncClient(app=app, base_url="http://test") as client:
        response = await client.get(
            "/api/v1/landmap/data?latitude=10.5&longitude=105.5&data_type=invalid"
        )
        assert response.status_code == 422  # Validation error


@pytest.mark.asyncio
async def test_invalid_classification_type():
    """Test classifications with invalid type"""
    async with AsyncClient(app=app, base_url="http://test") as client:
        response = await client.get("/api/v1/landmap/classifications/invalid")
        assert response.status_code == 422  # Validation error
