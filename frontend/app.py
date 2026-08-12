import os
import requests
from flask import Flask, render_template, request, redirect, url_for, flash, jsonify

app = Flask(__name__)
app.secret_key = os.getenv("SECRET_KEY", "cloud-app-secret-key-12345")

BACKEND_URL = os.getenv("BACKEND_URL", "http://backend:8000")

def get_backend_data(endpoint, default=None):
    """Utility function to safely fetch data from backend REST API."""
    if default is None:
        default = []
    try:
        url = f"{BACKEND_URL.rstrip('/')}/{endpoint.lstrip('/')}"
        res = requests.get(url, timeout=4)
        if res.status_code == 200:
            return res.json()
    except Exception as e:
        print(f"Backend API fetch error ({endpoint}): {e}")
    return default

@app.route("/")
def dashboard():
    stats = get_backend_data("/api/stats", {"total_users": 0, "total_products": 0, "total_orders": 0})
    users = get_backend_data("/api/users", [])
    products = get_backend_data("/api/products", [])
    orders = get_backend_data("/api/orders", [])
    return render_template(
        "index.html",
        stats=stats,
        users_count=len(users),
        products_count=len(products),
        orders_count=len(orders),
        recent_orders=orders[-5:] if orders else []
    )

@app.route("/users")
def users_page():
    users = get_backend_data("/api/users", [])
    return render_template("users.html", users=users)

@app.route("/users/add", methods=["POST"])
def add_user():
    name = request.form.get("name")
    email = request.form.get("email")
    role = request.form.get("role", "User")
    try:
        url = f"{BACKEND_URL.rstrip('/')}/api/users"
        res = requests.post(url, json={"name": name, "email": email, "role": role}, timeout=4)
        if res.status_code == 201:
            flash("User created successfully!", "success")
        else:
            flash(res.json().get("detail", "Error creating user"), "danger")
    except Exception as e:
        flash(f"Backend connection error: {e}", "danger")
    return redirect(url_for("users_page"))

@app.route("/products")
def products_page():
    products = get_backend_data("/api/products", [])
    return render_template("products.html", products=products)

@app.route("/products/add", methods=["POST"])
def add_product():
    name = request.form.get("name")
    sku = request.form.get("sku")
    price = float(request.form.get("price", 0))
    stock = int(request.form.get("stock", 0))
    category = request.form.get("category", "General")
    try:
        url = f"{BACKEND_URL.rstrip('/')}/api/products"
        res = requests.post(url, json={
            "name": name, "sku": sku, "price": price, "stock": stock, "category": category
        }, timeout=4)
        if res.status_code == 201:
            flash("Product added successfully!", "success")
        else:
            flash(res.json().get("detail", "Error adding product"), "danger")
    except Exception as e:
        flash(f"Backend connection error: {e}", "danger")
    return redirect(url_for("products_page"))

@app.route("/orders")
def orders_page():
    orders = get_backend_data("/api/orders", [])
    users = get_backend_data("/api/users", [])
    products = get_backend_data("/api/products", [])
    return render_template("orders.html", orders=orders, users=users, products=products)

@app.route("/orders/add", methods=["POST"])
def add_order():
    user_id = int(request.form.get("user_id", 0))
    product_id = int(request.form.get("product_id", 0))
    quantity = int(request.form.get("quantity", 1))
    try:
        url = f"{BACKEND_URL.rstrip('/')}/api/orders"
        res = requests.post(url, json={
            "user_id": user_id, "product_id": product_id, "quantity": quantity
        }, timeout=4)
        if res.status_code == 201:
            flash("Order placed successfully!", "success")
        else:
            flash(res.json().get("detail", "Error placing order"), "danger")
    except Exception as e:
        flash(f"Backend connection error: {e}", "danger")
    return redirect(url_for("orders_page"))

@app.route("/health")
def health():
    backend_status = "unreachable"
    try:
        res = requests.get(f"{BACKEND_URL.rstrip('/')}/api/health", timeout=2)
        if res.status_code == 200:
            backend_status = "healthy"
    except Exception:
        pass
    return jsonify({"frontend": "healthy", "backend": backend_status})

if __name__ == "__main__":
    port = int(os.getenv("PORT", 5000))
    app.run(host="0.0.0.0", port=port, debug=True)
