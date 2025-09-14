from fastapi import APIRouter
from pydantic import BaseModel


class HealthResponse(BaseModel):
    """Health check response model"""
    status: str
    service: str
    version: str = None

    class Config:
        json_schema_extra = {
            "example": {
                "status": "healthy",
                "service": "orders-service",
                "version": "1.0.0"
            }
        }


router = APIRouter(prefix="/health", tags=["health"])


@router.get(
    "/",
    response_model=HealthResponse,
    summary="Health check",
    description="Basic health check endpoint to verify service is running",
    responses={
        200: {
            "description": "Service is healthy",
            "content": {
                "application/json": {
                    "example": {
                        "status": "healthy",
                        "service": "orders-service",
                        "version": "1.0.0"
                    }
                }
            }
        }
    }
)
async def health_check():
    """Health check endpoint for orders service"""
    return HealthResponse(
        status="healthy",
        service="orders-service",
        version="1.0.0"
    )


@router.get(
    "/ready",
    response_model=HealthResponse,
    summary="Readiness check",
    description="Readiness probe for container orchestration - indicates service is ready to accept traffic",
    responses={
        200: {
            "description": "Service is ready",
            "content": {
                "application/json": {
                    "example": {
                        "status": "ready",
                        "service": "orders-service"
                    }
                }
            }
        }
    }
)
async def readiness_check():
    """Readiness check endpoint"""
    return HealthResponse(
        status="ready",
        service="orders-service"
    )


@router.get(
    "/live",
    response_model=HealthResponse,
    summary="Liveness check",
    description="Liveness probe for container orchestration - indicates service is alive",
    responses={
        200: {
            "description": "Service is alive",
            "content": {
                "application/json": {
                    "example": {
                        "status": "alive",
                        "service": "orders-service"
                    }
                }
            }
        }
    }
)
async def liveness_check():
    """Liveness check endpoint"""
    return HealthResponse(
        status="alive",
        service="orders-service"
    )