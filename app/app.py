"""Tiny Flask service used as the target for the DevSecOps pipeline."""
import os
from flask import Flask, jsonify, request

MAX_NAME_LEN = 50


def create_app() -> Flask:
    app = Flask(__name__)

    @app.after_request
    def security_headers(resp):
        resp.headers["X-Content-Type-Options"] = "nosniff"
        resp.headers["X-Frame-Options"] = "DENY"
        resp.headers["Content-Security-Policy"] = "default-src 'none'; frame-ancestors 'none'"
        resp.headers["Referrer-Policy"] = "no-referrer"
        resp.headers["Cache-Control"] = "no-store"
        resp.headers["Permissions-Policy"] = "geolocation=(), camera=(), microphone=()"
        return resp

    @app.get("/")
    def index():
        html = (
            "<!doctype html><html lang='en'><head><meta charset='utf-8'>"
            "<title>DevSecOps Lab</title></head><body>"
            "<h1>Azure DevSecOps Lab</h1>"
            "<ul><li><a href='/api/info'>/api/info</a></li>"
            "<li><a href='/api/greet?name=ninja'>/api/greet?name=ninja</a></li>"
            "<li><a href='/healthz'>/healthz</a></li></ul>"
            "</body></html>"
        )
        return html, 200, {"Content-Type": "text/html; charset=utf-8"}

    @app.get("/healthz")
    def healthz():
        return jsonify(status="ok")

    @app.get("/api/info")
    def info():
        return jsonify(
            service="azure-devsecops-lab",
            version=os.getenv("APP_VERSION", "dev"),
        )

    @app.get("/api/greet")
    def greet():
        name = request.args.get("name", "world")[:MAX_NAME_LEN]
        if not name.replace(" ", "").isalnum():
            return jsonify(error="name must be alphanumeric"), 400
        return jsonify(message=f"hello {name}")

    return app


app = create_app()
