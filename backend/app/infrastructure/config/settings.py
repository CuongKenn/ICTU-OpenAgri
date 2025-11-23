"""
Application settings and configuration.
"""
from functools import lru_cache
from typing import List
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Application settings."""
    
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=True
    )
    
    # Project
    PROJECT_NAME: str = "ICTU-OpenAgri"
    VERSION: str = "1.0.0"
    API_V1_STR: str = "/api/v1"
    
    # CORS
    CORS_ORIGINS: List[str] = ["http://localhost:3000", "http://localhost:5173"]
    
    # Database
    DATABASE_URL: str = "sqlite+aiosqlite:///./ictu_openagri.db"
    
    # Security
    SECRET_KEY: str = "your-secret-key-change-in-production"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    
    # Environment
    ENVIRONMENT: str = "development"

    # Sentinel
    COPERNICUS_USERNAME: str = ""
    COPERNICUS_PASSWORD: str = ""
    OUTPUT_DIR: str = "./output"
    MAX_PRODUCTS: int = 2


@lru_cache()
def get_settings() -> Settings:
    """Get cached settings instance."""
    return Settings()
