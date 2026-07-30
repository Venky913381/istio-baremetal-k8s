from flask import Flask, jsonify, request
import os
import psycopg2
from psycopg2.extras import RealDictCursor

app = Flask(__name__)

DB_HOST = os.getenv("DB_HOST", "postgres")
DB_PORT = int(os.getenv("DB_PORT", 5432))
DB_NAME = os.getenv("DB_NAME", "webappdb")
DB_USER = os.getenv("DB_USER", "webapp")
DB_PASSWORD = os.getenv("DB_PASSWORD", "webapppass")

def get_conn():
    return psycopg2.connect(
        host=DB_HOST,
        port=DB_PORT,
        dbname=DB_NAME,
        user=DB_USER,
        password=DB_PASSWORD
    )

@app.route("/")
def index():
    return jsonify(message="Backend service running")

@app.route("/healthz")
def health():
    return "ok", 200

@app.route("/api/items", methods=["GET", "POST"])
def items():
    if request.method == "GET":
        conn = get_conn()
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute("SELECT id, name FROM items ORDER BY id")
        rows = cur.fetchall()
        cur.close()
        conn.close()
        return jsonify(rows)
    else:
        data = request.get_json() or {}
        name = data.get("name")
        if not name:
            return jsonify({"error": "name is required"}), 400
        conn = get_conn()
        cur = conn.cursor()
        cur.execute("INSERT INTO items (name) VALUES (%s) RETURNING id", (name,))
        new_id = cur.fetchone()[0]
        conn.commit()
        cur.close()
        conn.close()
        return jsonify({"id": new_id, "name": name}), 201

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
