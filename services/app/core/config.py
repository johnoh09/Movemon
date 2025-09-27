from pydantic_settings import BaseSettings, SettingsConfigDict
from pydantic import field_validator
from typing import List, Literal

class Settings(BaseSettings):
    app_name: str = "FastAPI Starter"
    app_env: str = "dev" 
    env: Literal["dev", "prod", "test"] = "dev"
    sql_echo: bool = False
    app_host: str = "0.0.0.0"
    app_port: int = 8000
    allowed_origins: List[str] = ["*"]
    log_level: str = "INFO"
    database_url: str = ""
    auto_create_db: bool = False

    # JWT
    jwt_secret: str = "CHANGE_ME"       # 반드시 환경변수로 교체
    jwt_algorithm: str = "HS256"
    access_token_expires_minutes: int = 60 * 24 * 7  # 7일

    @field_validator("allowed_origins", mode="before")
    @classmethod
    def split_origins(cls, v):
        if isinstance(v, str):
            # support comma-separated string
            return [s.strip() for s in v.split(",") if s.strip()]
        return v

    model_config = {
        "env_prefix": "",
        "case_sensitive": False,
        "env_file": ".env",
    }

settings = Settings()
