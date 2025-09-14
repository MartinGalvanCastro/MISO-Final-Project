# MediSupply Local Development Environment

Simple local testing setup for the MediSupply microservices.

## Services

- **PostgreSQL** - Shared database for both services
- **Orders Service** - Main service handling order processing
- **Inventory Service** - Service for inventory management

**Note:** SQS calls are mocked and only logged - no LocalStack needed.

## Quick Start

1. **Start the environment:**
   ```bash
   cd /home/khzdev/repos/tesis/services
   docker-compose up -d
   ```

2. **Check service status:**
   ```bash
   docker-compose ps
   ```

3. **View logs:**
   ```bash
   docker-compose logs -f orders-service
   docker-compose logs -f inventory-service
   ```

## Service URLs

- **Orders Service API:** http://localhost:8001/api/orders/docs
- **Inventory Service API:** http://localhost:8002/api/inventory/docs
- **Database:** localhost:5432 (postgres/password/medisupply)

## Testing

### Health Checks
```bash
curl http://localhost:8001/api/orders/health
curl http://localhost:8002/api/inventory/health
```

### Sample Order Creation
```bash
curl -X POST "http://localhost:8001/api/orders" \
  -H "Content-Type: application/json" \
  -d '{
    "customer_id": "customer-123",
    "items": [
      {
        "product_id": "product-456",
        "quantity": 2,
        "unit_price": 29.99
      }
    ]
  }'
```

## Environment Variables

Each service has its own `.env` file:
- `orders-service/.env`
- `inventory-service/.env`
- `.env` (global docker-compose variables)

## Stopping the Environment

```bash
docker-compose down
```

To remove volumes (reset database):
```bash
docker-compose down -v
```

## Development

Services are configured with volume mounts and auto-reload for development:
- Code changes trigger automatic reloads
- Database migrations run automatically on orders-service startup
- LocalStack SQS queue is created automatically