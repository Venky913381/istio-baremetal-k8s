"""Inventory: stock levels per product id."""
import socket

from flask import Flask, jsonify

app = Flask(__name__)

POD = socket.gethostname()
STOCK = {"1": 12, "2": 40, "3": 0, "4": 7}


@app.get("/healthz")
def healthz():
    return {"status": "ok"}


@app.get("/api/stock")
def stock():
    return jsonify(pod=POD, stock=STOCK)
