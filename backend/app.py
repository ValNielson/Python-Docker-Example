import os
from datetime import datetime

from flask import Flask, jsonify, request
import psycopg2

app = Flask(__name__)

DATABASE_URL = os.environ["DATABASE_URL"]


def get_db():
    conn = psycopg2.connect(DATABASE_URL)
    return conn


def init_db():
    conn = get_db()
    cur = conn.cursor()
    cur.execute("""
        CREATE TABLE IF NOT EXISTS guestbook (
            id SERIAL PRIMARY KEY,
            name VARCHAR(100) NOT NULL,
            message VARCHAR(500) NOT NULL,
            created_at TIMESTAMP DEFAULT NOW()
        )
    """)
    conn.commit()
    cur.close()
    conn.close()


@app.route("/api/entries", methods=["GET"])
def get_entries():
    conn = get_db()
    cur = conn.cursor()
    cur.execute("SELECT name, message, created_at FROM guestbook ORDER BY created_at DESC")
    rows = cur.fetchall()
    cur.close()
    conn.close()
    entries = [
        {"name": r[0], "message": r[1], "created_at": r[2].strftime("%B %d, %Y %I:%M %p")}
        for r in rows
    ]
    return jsonify(entries)


@app.route("/api/entries", methods=["POST"])
def add_entry():
    data = request.get_json()
    name = data.get("name", "").strip()[:100]
    message = data.get("message", "").strip()[:500]
    if not name or not message:
        return jsonify({"error": "Name and message are required"}), 400
    conn = get_db()
    cur = conn.cursor()
    cur.execute("INSERT INTO guestbook (name, message) VALUES (%s, %s)", (name, message))
    conn.commit()
    cur.close()
    conn.close()
    return jsonify({"ok": True}), 201


if __name__ == "__main__":
    init_db()
    app.run(host="0.0.0.0", port=5000)
