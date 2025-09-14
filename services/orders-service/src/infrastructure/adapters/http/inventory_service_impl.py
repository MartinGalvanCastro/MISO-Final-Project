import logging
from typing import Dict, List

import httpx

from src.application.ports.inventory_service import InventoryService
from src.infrastructure.config.settings import settings

logger = logging.getLogger(__name__)


class HTTPInventoryService(InventoryService):
    
    def __init__(self):
        self.base_url = settings.INVENTORY_SERVICE_URL
        self.timeout = httpx.Timeout(5.0, connect=2.0)
        self.max_retries = 3
    
    async def check_stock(self, product_ids: list[str]) -> dict[str, int]:
        """
        Check stock availability for products
        Returns empty dict on error (fail-safe)
        """
        async with httpx.AsyncClient(timeout=self.timeout) as client:
            for attempt in range(self.max_retries):
                try:
                    response = await client.post(
                        f"{self.base_url}/api/v1/inventory/check",
                        json={"product_ids": product_ids}
                    )
                    response.raise_for_status()
                    
                    data = response.json()
                    return data.get("stock", {})
                    
                except httpx.TimeoutException:
                    logger.warning(f"Timeout checking inventory (attempt {attempt + 1}/{self.max_retries})")
                    if attempt == self.max_retries - 1:
                        logger.error("All retry attempts failed for inventory check")
                        return {}
                    
                except httpx.HTTPStatusError as e:
                    logger.error(f"HTTP error checking inventory: {e.response.status_code}")
                    return {}
                    
                except Exception as e:
                    logger.error(f"Unexpected error checking inventory: {str(e)}")
                    return {}
        
        return {}
    
    async def reserve_stock(self, items: Dict[str, int]) -> bool:
        """
        Reserve stock for order items
        Returns False on any error
        """
        async with httpx.AsyncClient(timeout=self.timeout) as client:
            try:
                response = await client.post(
                    f"{self.base_url}/api/v1/inventory/reserve",
                    json={"items": items}
                )
                response.raise_for_status()
                
                data = response.json()
                return data.get("reserved", False)
                
            except httpx.TimeoutException:
                logger.error("Timeout reserving stock")
                return False
                
            except httpx.HTTPStatusError as e:
                logger.error(f"HTTP error reserving stock: {e.response.status_code}")
                return False
                
            except Exception as e:
                logger.error(f"Unexpected error reserving stock: {str(e)}")
                return False