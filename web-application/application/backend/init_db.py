#!/usr/bin/env python3
import os
import psycopg2

DB_HOST = os.getenv("DB_HOST", "postgres")
DB_PORT = int(os.getenv("DB_PORT", 5432))
DB_NAME = os.getenv("DB_NAME", "webappdb")
DB_USER = os.getenv("DB_USER", "webapp")
DB_PASSWORD = os.getenv("DB_PASSWORD", "webapppass")

conn = psycopg2.connect(host=DB_HOST, port=DB_PORT, dbname=DB_NAME, user=DB_USER, password=DB_PASSWORD)
cur = conn.cursor()
cur.execute("CREATE TABLE IF NOT EXISTS items (id SERIAL PRIMARY KEY, name TEXT NOT NULL)")
conn.commit()
cur.close()
conn.close()
print("DB initialized")
