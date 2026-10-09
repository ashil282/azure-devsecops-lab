import sys
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from app import create_app  # noqa: E402


@pytest.fixture()
def client():
    return create_app().test_client()


def test_healthz(client):
    resp = client.get("/healthz")
    assert resp.status_code == 200
    assert resp.get_json() == {"status": "ok"}


def test_index_is_html(client):
    resp = client.get("/")
    assert resp.status_code == 200
    assert "text/html" in resp.content_type


def test_info_has_version(client):
    data = client.get("/api/info").get_json()
    assert data["service"] == "azure-devsecops-lab"
    assert "version" in data


def test_greet_ok(client):
    assert client.get("/api/greet?name=ninja").get_json() == {
        "message": "hello ninja"
    }


def test_greet_rejects_injection(client):
    resp = client.get("/api/greet?name=<script>alert(1)</script>")
    assert resp.status_code == 400


def test_security_headers(client):
    resp = client.get("/healthz")
    assert resp.headers["X-Content-Type-Options"] == "nosniff"
    assert resp.headers["X-Frame-Options"] == "DENY"
    assert "default-src 'none'" in resp.headers["Content-Security-Policy"]
