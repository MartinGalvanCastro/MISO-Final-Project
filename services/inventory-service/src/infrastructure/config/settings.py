from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    # Application
    APP_NAME: str = "inventory-service"
    PORT: int = 8002
    DEBUG: bool = False
    ENVIRONMENT: str = "development"
    LOG_LEVEL: str = "INFO"

    # Database
    DATABASE_URL: str = "postgresql+asyncpg://user:password@localhost/medisupply"
    DATABASE_HOST: str = "localhost"
    DATABASE_PORT: int = 5432
    DATABASE_NAME: str = "medisupply"
    DATABASE_USER: str = "postgres"
    DATABASE_PASSWORD: str = "password"

    # Health Check
    HEALTH_CHECK_PATH: str = "/api/inventory/health"

    # Inventory Specific Settings
    DEFAULT_STOCK_QUANTITY: int = 100
    LOW_STOCK_THRESHOLD: int = 10
    RESERVATION_TIMEOUT_MINUTES: int = 15

    class Config:
        env_file = ".env"
        extra = "ignore"  # Ignore extra fields


settings = Settings()