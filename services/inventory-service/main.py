from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import uvicorn
import logging
from prometheus_fastapi_instrumentator import Instrumentator

from src.infrastructure.api.controllers.inventory_controller import router as inventory_router
from src.infrastructure.api.controllers.health_controller import router as health_router
from src.infrastructure.config.settings import settings
from src.infrastructure.api.exception_handlers import EXCEPTION_HANDLERS

# Configure logging
logging.basicConfig(
    level=logging.INFO if not settings.DEBUG else logging.DEBUG,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)

logger = logging.getLogger(__name__)

# Create FastAPI app
app = FastAPI(
    title="Inventory Service",
    version="3.0.0",
    docs_url="/api/v1/inventory/docs",
    openapi_url="/api/v1/inventory/openapi.json",
    description="""
## Inventory Service API

A microservice for managing inventory and stock in the medical supply e-commerce system, built with hexagonal architecture.

### Features

* **Stock Management**: Check availability and manage product stock levels
* **Stock Reservation**: Atomic reservation system for order processing
* **Real-time Availability**: Current stock levels with reserved quantities
* **Health Monitoring**: Health, readiness, and liveness endpoints

### Architecture

This service implements hexagonal architecture (ports and adapters) with:

- **Domain Layer**: Core inventory business logic and entities
- **Application Layer**: Stock management use cases and workflows
- **Infrastructure Layer**: External integrations (database, HTTP, messaging)

### Stock Management Flow

1. **Stock Check**: Query available stock for products
2. **Stock Reservation**: Reserve items for pending orders
3. **Stock Confirmation**: Confirm reservations when orders are completed
4. **Stock Release**: Release reservations when orders are cancelled

### Inventory Operations

**Check Stock**: Returns current available quantities for requested products
- Used by orders service during order validation
- Shows only available stock (not including reserved quantities)
- Products not found return quantity 0

**Reserve Stock**: Atomically reserves stock for order items
- All-or-nothing operation - either all items are reserved or none are
- Validates sufficient stock is available for all requested items
- Reserved stock is held for configurable TTL period
- Failed reservations do not affect any inventory levels

### Business Rules

- Stock reservations are atomic across all items
- Reserved stock has configurable expiration time
- Negative stock levels are not allowed
- Stock operations are fully transactional
    """,
    contact={
        "name": "Development Team",
        "email": "dev@medisupply.com",
    },
    license_info={
        "name": "MIT",
        "url": "https://opensource.org/licenses/MIT",
    },
    tags_metadata=[
        {
            "name": "inventory",
            "description": "Inventory management operations. Check stock availability and reserve items for orders.",
        },
        {
            "name": "health",
            "description": "Health check endpoints for monitoring service status and container orchestration probes.",
        },
    ],
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# Register exception handlers
for exception_class, handler in EXCEPTION_HANDLERS.items():
    app.add_exception_handler(exception_class, handler)

# Initialize Prometheus metrics first with exclusions for health and metrics endpoints
instrumentator = Instrumentator()
instrumentator.instrument(app, excluded_handlers=["/api/v1/inventory/health/", "/api/v1/inventory/health", "/api/v1/inventory/metrics"]).expose(app, endpoint="/api/v1/inventory/metrics")

# Include routers - ORDER MATTERS! Health router must come before inventory router, and metrics must be registered before inventory router
app.include_router(health_router)
app.include_router(inventory_router)


@app.on_event("startup")
async def startup():
    logger.info(f"Starting {settings.APP_NAME} on port {settings.PORT}")
    logger.info(f"Environment: {settings.ENVIRONMENT}")
    logger.info("Prometheus metrics enabled at /api/v1/inventory/metrics")


@app.on_event("shutdown")
async def shutdown():
    logger.info(f"Shutting down {settings.APP_NAME}")


if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=settings.PORT,
        reload=settings.DEBUG
    )