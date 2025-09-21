import logging

import uvicorn
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from prometheus_fastapi_instrumentator import Instrumentator
from prometheus_client import Gauge

from src.infrastructure.api.controllers.order_controller import router as order_router
from src.infrastructure.api.controllers.health_controller import router as health_router
from src.infrastructure.config.settings import settings
from src.infrastructure.api.exception_handlers import EXCEPTION_HANDLERS

# Configure logging
logging.basicConfig(
    level=logging.INFO if not settings.DEBUG else logging.DEBUG,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)

logger = logging.getLogger(__name__)

# Create instance count metric
service_instance_count = Gauge('service_instance_count', 'Number of service instances', ['service_name'])
service_instance_count.labels(service_name='orders-service').set(1)

# Create FastAPI app
app = FastAPI(
    title="Orders Service",
    version="3.0.0",
    docs_url="/api/v1/orders/docs",
    openapi_url="/api/v1/orders/openapi.json",
    description="""
## Orders Service API

A microservice for managing orders in the medical supply e-commerce system, built with hexagonal architecture.

### Features

* **Order Management**: Create, retrieve, and track orders
* **Business Validation**: Automatic validation of order rules and constraints
* **Inventory Integration**: Real-time stock checking and reservation
* **Event Publishing**: Order events published to message queue
* **Health Monitoring**: Health, readiness, and liveness endpoints

### Architecture

This service implements hexagonal architecture (ports and adapters) with:

- **Domain Layer**: Core business logic and entities
- **Application Layer**: Use cases and business workflows
- **Infrastructure Layer**: External integrations (database, HTTP, messaging)

### Order Processing Flow

1. **Order Creation**: Client submits order with items
2. **Validation**: Business rules are validated (minimum amount, item limits, etc.)
3. **Inventory Check**: Stock availability is verified with inventory service
4. **Stock Reservation**: Items are reserved if available
5. **Order Confirmation**: Order is created with delivery date
6. **Event Publishing**: Order events are published for downstream processing

### Order Statuses

- `pending`: Order created but not yet validated
- `validated`: Order passed business rule validation
- `created`: Order successfully created and stock reserved
- `rejected`: Order rejected due to validation or stock issues

### Business Rules

- Minimum order total: $10.00
- Maximum items per order: 100
- All quantities must be positive
- All prices must be non-negative
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
            "name": "orders",
            "description": "Order management operations. Create, retrieve, and manage orders with full business validation.",
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

# Initialize Prometheus metrics first with path exclusions
instrumentator = Instrumentator(
    excluded_handlers=[".*/health.*", ".*/metrics.*"]
)
instrumentator.instrument(app).expose(app, endpoint="/api/v1/orders/metrics")

# Include routers - ORDER MATTERS! Health router must come before order router, and metrics must be registered before order router
app.include_router(health_router)
app.include_router(order_router)


@app.on_event("startup")
async def startup():
    logger.info(f"Starting {settings.APP_NAME} on port {settings.PORT}")
    logger.info(f"Environment: {settings.ENVIRONMENT}")
    logger.info("Prometheus metrics enabled at /api/v1/orders/metrics")


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