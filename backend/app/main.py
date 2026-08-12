from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from typing import List
import os

from .database import engine, get_db, Base
from . import models, schemas

# Initialize database tables
try:
    Base.metadata.create_all(bind=engine)
except Exception as e:
    print(f"Database initialization error (will retry on connect): {e}")

app = FastAPI(
    title="Cloud Microservice Backend API",
    description="REST API for User, Product, and Order Management",
    version="1.0.0"
)

# Enable CORS for frontend integration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.on_event("startup")
def seed_initial_data():
    """Seed initial demo data if database is empty."""
    try:
        db = next(get_db())
        if db.query(models.User).count() == 0:
            user1 = models.User(name="Alice Johnson", email="alice@example.com", role="Admin")
            user2 = models.User(name="Bob Smith", email="bob@example.com", role="Developer")
            user3 = models.User(name="Charlie Brown", email="charlie@example.com", role="User")
            db.add_all([user1, user2, user3])
            db.commit()

        if db.query(models.Product).count() == 0:
            prod1 = models.Product(name="Kubernetes Cluster", sku="K8S-001", price=299.99, stock=50, category="Cloud Infrastructure")
            prod2 = models.Product(name="ECS Fargate Task", sku="ECS-002", price=49.99, stock=200, category="Containers")
            prod3 = models.Product(name="AWS ALB Load Balancer", sku="ALB-003", price=89.99, stock=100, category="Networking")
            db.add_all([prod1, prod2, prod3])
            db.commit()

        if db.query(models.Order).count() == 0:
            order1 = models.Order(user_id=1, product_id=1, quantity=2, total_price=599.98, status="Completed")
            order2 = models.Order(user_id=2, product_id=2, quantity=5, total_price=249.95, status="Pending")
            db.add_all([order1, order2])
            db.commit()
    except Exception as e:
        print(f"Seed data warning: {e}")


@app.get("/", tags=["General"])
def root():
    return {
        "service": "Backend API",
        "status": "online",
        "version": "1.0.0",
        "endpoints": {
            "health": "/api/health",
            "users": "/api/users",
            "products": "/api/products",
            "orders": "/api/orders",
            "stats": "/api/stats"
        }
    }


@app.get("/api/health", tags=["General"])
def health_check():
    return {"status": "healthy", "service": "backend"}


@app.get("/api/stats", tags=["General"])
def get_stats(db: Session = Depends(get_db)):
    users_count = db.query(models.User).count()
    products_count = db.query(models.Product).count()
    orders_count = db.query(models.Order).count()
    return {
        "total_users": users_count,
        "total_products": products_count,
        "total_orders": orders_count
    }


# ================= USER ROUTES =================
@app.get("/api/users", response_model=List[schemas.UserResponse], tags=["Users"])
def get_users(db: Session = Depends(get_db)):
    return db.query(models.User).all()


@app.post("/api/users", response_model=schemas.UserResponse, status_code=status.HTTP_201_CREATED, tags=["Users"])
def create_user(user: schemas.UserCreate, db: Session = Depends(get_db)):
    existing = db.query(models.User).filter(models.User.email == user.email).first()
    if existing:
        raise HTTPException(status_code=400, detail="Email already registered")
    db_user = models.User(name=user.name, email=user.email, role=user.role)
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user


@app.delete("/api/users/{user_id}", tags=["Users"])
def delete_user(user_id: int, db: Session = Depends(get_db)):
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    db.delete(user)
    db.commit()
    return {"message": "User deleted successfully"}


# ================= PRODUCT ROUTES =================
@app.get("/api/products", response_model=List[schemas.ProductResponse], tags=["Products"])
def get_products(db: Session = Depends(get_db)):
    return db.query(models.Product).all()


@app.post("/api/products", response_model=schemas.ProductResponse, status_code=status.HTTP_201_CREATED, tags=["Products"])
def create_product(product: schemas.ProductCreate, db: Session = Depends(get_db)):
    existing = db.query(models.Product).filter(models.Product.sku == product.sku).first()
    if existing:
        raise HTTPException(status_code=400, detail="Product SKU already exists")
    db_product = models.Product(
        name=product.name,
        sku=product.sku,
        price=product.price,
        stock=product.stock,
        category=product.category
    )
    db.add(db_product)
    db.commit()
    db.refresh(db_product)
    return db_product


@app.delete("/api/products/{product_id}", tags=["Products"])
def delete_product(product_id: int, db: Session = Depends(get_db)):
    prod = db.query(models.Product).filter(models.Product.id == product_id).first()
    if not prod:
        raise HTTPException(status_code=404, detail="Product not found")
    db.delete(prod)
    db.commit()
    return {"message": "Product deleted successfully"}


# ================= ORDER ROUTES =================
@app.get("/api/orders", response_model=List[schemas.OrderResponse], tags=["Orders"])
def get_orders(db: Session = Depends(get_db)):
    return db.query(models.Order).all()


@app.post("/api/orders", response_model=schemas.OrderResponse, status_code=status.HTTP_201_CREATED, tags=["Orders"])
def create_order(order: schemas.OrderCreate, db: Session = Depends(get_db)):
    user = db.query(models.User).filter(models.User.id == order.user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    product = db.query(models.Product).filter(models.Product.id == order.product_id).first()
    if not product:
        raise HTTPException(status_code=404, detail="Product not found")
    
    total = product.price * order.quantity
    db_order = models.Order(
        user_id=order.user_id,
        product_id=order.product_id,
        quantity=order.quantity,
        total_price=round(total, 2),
        status="Completed"
    )
    db.add(db_order)
    db.commit()
    db.refresh(db_order)
    return db_order
