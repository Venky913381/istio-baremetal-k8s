"""Frontend: web page + JSON API. Calls backend, which calls inventory."""
import os
import socket

import requests
from flask import Flask, jsonify, render_template_string, request

app = Flask(__name__)

BACKEND_URL = os.getenv("BACKEND_URL", "http://backend:8080")
EGRESS_URL = os.getenv("EGRESS_URL", "https://httpbin.org/get")
TIMEOUT = float(os.getenv("UPSTREAM_TIMEOUT", "10"))
POD = socket.gethostname()

# Istio routes on headers and joins traces from them, so every hop must forward these.
PROPAGATED_HEADERS = [
    "x-request-id", "traceparent", "tracestate",
    "x-b3-traceid", "x-b3-spanid", "x-b3-parentspanid", "x-b3-sampled", "x-b3-flags", "b3",
    "end-user",
]


def forward_headers():
    headers = {h: request.headers[h] for h in PROPAGATED_HEADERS if h in request.headers}
    user = request.args.get("user")  # lets a browser test header routing: /?user=tester
    if user:
        headers["end-user"] = user
    return headers


def call(url):
    """Return (status, body) and never raise, so mesh failures show up in the response."""
    try:
        resp = requests.get(url, headers=forward_headers(), timeout=TIMEOUT)
    except requests.RequestException as exc:
        return 503, {"error": f"{type(exc).__name__}: {exc}"}
    try:
        body = resp.json()
    except ValueError:
        body = {"error": resp.text[:300]}
    return resp.status_code, body


@app.get("/healthz")
def healthz():
    return {"status": "ok"}


@app.get("/api/products")
def products():
    status, body = call(f"{BACKEND_URL}/api/products")
    return jsonify(frontend=POD, backend_status=status, backend=body), status


@app.get("/api/flaky")
def flaky():
    status, body = call(f"{BACKEND_URL}/api/flaky")
    return jsonify(frontend=POD, backend_status=status, backend=body), status


@app.get("/api/egress")
def egress():
    status, body = call(EGRESS_URL)
    return jsonify(frontend=POD, url=EGRESS_URL, status=status, body=body), status


PAGE = """<!doctype html>
<html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>Istio POC Shop</title>
<style>
body{font-family:system-ui,sans-serif;max-width:760px;margin:2rem auto;padding:0 1rem;color:#222}
.tag{display:inline-block;padding:.15rem .5rem;border-radius:4px;color:#fff;font-weight:600}
.v1{background:#2563eb}.v2{background:#dc2626}.err{background:#b45309}
table{border-collapse:collapse;width:100%;margin-top:1rem}td,th{border:1px solid #ddd;padding:.4rem;text-align:left}
.box{background:#fef3c7;border:1px solid #f59e0b;padding:.6rem;margin-top:1rem;white-space:pre-wrap}
small{color:#666}
</style></head><body>
<h1>Istio POC Shop</h1>
<p><small>frontend pod: {{ pod }}{% if user %} &middot; end-user: {{ user }}{% endif %}</small></p>
{% if data.version %}
<p>Served by backend <span class="tag {{ data.version }}">{{ data.version }}</span> <small>pod {{ data.pod }}</small></p>
<table>
<tr><th>Product</th><th>Price</th><th>Stock</th>{% if data.version == 'v2' %}<th>Rating</th>{% endif %}</tr>
{% for p in data.products %}
<tr><td>{{ p.name }}</td><td>${{ '%.2f'|format(p.price) }}</td>
<td>{{ p.stock if p.stock is not none else 'unavailable' }}</td>
{% if data.version == 'v2' %}<td>{{ '&#9733;'|safe * p.rating }}</td>{% endif %}</tr>
{% endfor %}
</table>
{% if data.inventory.error %}<div class="box">inventory error: {{ data.inventory.error }}</div>{% endif %}
{% else %}
<p><span class="tag err">backend error {{ status }}</span></p>
<div class="box">{{ data }}</div>
{% endif %}
</body></html>"""


@app.get("/")
def index():
    status, body = call(f"{BACKEND_URL}/api/products")
    return render_template_string(PAGE, pod=POD, status=status, data=body, user=request.args.get("user", ""))
