from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    # Application
    APP_NAME: str = "orders-service"
    PORT: int = 8001
    DEBUG: bool = False
    ENVIRONMENT: str = "development"  # local, development, production
    LOG_LEVEL: str = "INFO"

    # Database
    DATABASE_URL: str = "postgresql+asyncpg://user:password@localhost/medisupply"
    DATABASE_HOST: str = "localhost"
    DATABASE_PORT: str = "5432"
    DATABASE_NAME: str = "medisupply"
    DATABASE_USER: str = "postgres"
    DATABASE_PASSWORD: str = "password"

    # External Services
    INVENTORY_SERVICE_URL: str = "http://localhost:8002"

    # AWS
    AWS_REGION: str = "us-east-1"
    AWS_ACCESS_KEY_ID: str = ""
    AWS_SECRET_ACCESS_KEY: str = ""
    SQS_QUEUE_URL: str = ""
    SQS_QUEUE_NAME: str = "orders-queue"
    AWS_ENDPOINT_URL: str = ""  # For LocalStack

    # Health Check
    HEALTH_CHECK_PATH: str = "/api/orders/health"

    class Config:
        env_file = ".env"


settings = Settings()