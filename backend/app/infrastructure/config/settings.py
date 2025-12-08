
# Licensed under the MIT License. See LICENSE file in the project root for full license information.

"""
Application settings and configuration.
"""
import os
from functools import lru_cache
from typing import List
from pydantic_settings import BaseSettings, SettingsConfigDict


BASE_DIR = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
ENV_FILE_PATH = os.path.join(BASE_DIR, ".env")

class Settings(BaseSettings):
    """Application settings."""
    
    model_config = SettingsConfigDict(
        env_file=ENV_FILE_PATH,
        env_file_encoding="utf-8",
        case_sensitive=True,
        extra="ignore"
    )
    
    # Project
    PROJECT_NAME: str = "ICTU-OpenAgri"
    VERSION: str = "1.0.0"
    API_V1_STR: str = "/api/v1"
    
    # CORS
    CORS_ORIGINS: List[str] = ["*"]
    
    # Database
    DATABASE_URL: str = "sqlite+aiosqlite:///./ictu_openagri.db"
    
    # Security
    SECRET_KEY: str = "your-secret-key-change-in-production"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    
    # Environment
    ENVIRONMENT: str = "development"

    # Admin (Sẽ bị ghi đè bởi biến môi trường trong production)
    ADMIN_EMAIL: str = ""
    ADMIN_PASSWORD: str = ""

    # Sentinel
    COPERNICUS_USERNAME: str = ""
    COPERNICUS_PASSWORD: str = ""
    OUTPUT_DIR: str = "./output"
    MAX_PRODUCTS: int = 2

    # Gemini AI
    GEMINI_API_KEY: str = ""
    GEMINI_MODEL: str = "gemini-2.5-flash"
    GEMINI_SYSTEM_PROMPT: str = (
        "Bạn là trợ lý AI chuyên gia nông nghiệp Việt Nam. Luôn trả lời bằng tiếng Việt, "
        "dựa trên các thực hành canh tác bền vững, tư vấn cho nông dân về cây trồng, "
        "sâu bệnh, thời tiết và thị trường. Giải thích ngắn gọn, thực tế, đề xuất các bước "
        "hành động cụ thể và nhắc nhở tham khảo chuyên gia địa phương cho quyết định quan trọng."
    )
    GEMINI_KNOWLEDGE_PATH: str = os.path.join(BASE_DIR, "data", "agri_expert_tips.json")


@lru_cache()
def get_settings() -> Settings:
    """Get cached settings instance."""
    return Settings()
