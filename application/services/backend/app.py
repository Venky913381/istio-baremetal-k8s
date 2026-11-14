"""Backend: product catalogue. v1 = no ratings, v2 = with ratings. Calls inventory for stock."""
import os
import random
import socket

import requests
from flask import Flask, jsonify, request

app = Flask(__name__)

VERSION = os.getenv("VERSION", "v1")
INVENTORY_URL = os.getenv("INVENTORY_URL", "http://inventory:8080")
FAIL_PERCENT = int(os.getenv("FAIL_PERCENT", "50"))  # failure rate of /api/flaky
TIMEOUT = float(os.getenv("UPSTREAM_TIMEOUT", "10"))
POD = socket.gethostname()

PROPAGATED_HEADERS = [
    "x-request-id", "traceparent", "tracestate",
    "x-b3-traceid", "x-b3-spanid", "x-b3-parentspanid", "x-b3-sampled", "x-b3-flags", "b3",
    "end-user",
]

PRODUCTS = [
    {"id": 1, "name": "Envoy Proxy Hoodie", "price": 49.0, "rating": 5},
    {"id": 2, "name": "Sidecar Coffee Mug", "price": 12.5, "rating": 4},
    {"id": 3, "name": "Mesh Network Cable", "price": 8.99, "rating": 3},
    {"id": 4, "name": "Pilot Sunglasses", "price": 25.0, "rating": 4},
]


def fetch_stock():
    """Return (stock_by_id, inventory_info). Degrades gracefully so faults stay visible."""
    headers = {h: request.headers[h] for h in PROPAGATED_HEADERS if h in request.headers}
    try:
        resp = requests.get(f"{INVENTORY_URL}/api/stock", headers=headers, timeout=TIMEOUT)
        resp.raise_for_status()
        body = resp.json()
        return body.get("stock", {}), {"status": resp.status_code, "pod": body.get("pod")}
    except (requests.RequestException, ValueError) as exc:
        status = getattr(getattr(exc, "response", None), "status_code", None)
        return {}, {"status": status, "error": f"{type(exc).__name__}: {exc}"}


@app.get("/healthz")
def healthz():
    return {"status": "ok", "version": VERSION}


@app.get("/api/products")
def products():
    stock, inventory = fetch_stock()
    items = []
    for p in PRODUCTS:
        item = {"id": p["id"], "name": p["name"], "price": p["price"], "stock": stock.get(str(p["id"]))}
        if VERSION == "v2":
            item["rating"] = p["rating"]
        items.append(item)
    return jsonify(version=VERSION, pod=POD, products=items, inventory=inventory)


@app.get("/api/flaky")
def flaky():
    """Fails FAIL_PERCENT% of the time with HTTP 500 - for retry and outlier-detection tests."""
    if random.randint(1, 100) <= FAIL_PERCENT:
        return jsonify(version=VERSION, pod=POD, result="failed"), 500
    return jsonify(version=VERSION, pod=POD, result="ok")
