from fastapi import FastAPI

app = FastAPI(
    title="Inventory Service",
    description="Internal stock-lookup service, only called by the backend",
    version="1.0.0",
)

# In-memory stock, keyed by the same SKUs the backend seeds into Postgres.
STOCK = {
    "K8S-001": {"stock": 50},
    "ECS-002": {"stock": 200},
    "ALB-003": {"stock": 100},
}


@app.get("/", tags=["General"])
def root():
    return {"service": "Inventory Service", "status": "online", "version": "1.0.0"}


@app.get("/api/health", tags=["General"])
def health_check():
    return {"status": "healthy", "service": "inventory"}


@app.get("/api/inventory/{sku}", tags=["Inventory"])
def get_stock(sku: str):
    item = STOCK.get(sku)
    if not item:
        # Unknown SKUs are treated as available with no tracked stock.
        return {"sku": sku, "available": True, "stock": None}
    return {"sku": sku, "available": item["stock"] > 0, "stock": item["stock"]}
