"""
Tests for Ollama Model Explorer application.
"""

import json
import pytest
from unittest.mock import patch, MagicMock

from app import app, normalize_url, format_size, get_max_workers


@pytest.fixture
def client():
    """Create a test client for the app."""
    app.config["TESTING"] = True
    with app.test_client() as client:
        yield client


@pytest.fixture
def mock_ollama_response():
    """Mock Ollama API responses."""
    return {
        "models": [
            {
                "name": "llama2:latest",
                "size": 3826793472,
                "digest": "abc123def456",
                "modified_at": "2024-01-15T10:30:00Z",
            },
            {
                "name": "mistral:latest",
                "size": 4113301504,
                "digest": "def456abc789",
                "modified_at": "2024-01-14T08:20:00Z",
            },
        ]
    }


@pytest.fixture
def mock_model_details():
    """Mock model details response."""
    return {
        "capabilities": ["completion", "tools"],
        "details": {
            "parameter_size": "7B",
            "quantization_level": "Q4_0",
            "family": "llama",
            "format": "gguf",
        },
        "model_info": {"llama.context_length": 4096},
    }


class TestHealthEndpoint:
    """Tests for the health check endpoint."""

    def test_health_returns_ok(self, client):
        """Test that health endpoint returns healthy status."""
        response = client.get("/health")
        assert response.status_code == 200
        data = json.loads(response.data)
        assert data["status"] == "healthy"
        assert "version" in data


class TestIndexEndpoint:
    """Tests for the main index page."""

    def test_index_returns_html(self, client):
        """Test that index returns HTML page."""
        response = client.get("/")
        assert response.status_code == 200
        assert b"Ollama Model Explorer" in response.data


class TestFetchEndpoint:
    """Tests for the fetch models API endpoint."""

    def test_fetch_requires_json(self, client):
        """Test that fetch endpoint requires JSON."""
        response = client.post("/api/fetch")
        assert response.status_code == 400

    def test_fetch_requires_servers(self, client):
        """Test that fetch endpoint requires servers list."""
        response = client.post(
            "/api/fetch", data=json.dumps({}), content_type="application/json"
        )
        assert response.status_code == 400
        data = json.loads(response.data)
        assert "error" in data

    def test_fetch_validates_servers(self, client):
        """Test that fetch endpoint validates server URLs."""
        response = client.post(
            "/api/fetch",
            data=json.dumps({"servers": ["", "   "]}),
            content_type="application/json",
        )
        assert response.status_code == 400

    @patch("app.fetch_models_from_server")
    def test_fetch_returns_models(self, mock_fetch, client, mock_model_details):
        """Test that fetch endpoint returns models."""
        mock_fetch.return_value = {
            "server": "http://localhost:11434",
            "success": True,
            "models": [
                {
                    "name": "llama2:latest",
                    "server": "http://localhost:11434",
                    "capabilities": ["completion"],
                    "family": "llama",
                    "size": 3826793472,
                    "size_formatted": "3.6 GB",
                }
            ],
        }

        response = client.post(
            "/api/fetch",
            data=json.dumps({"servers": ["http://localhost:11434"]}),
            content_type="application/json",
        )

        assert response.status_code == 200
        data = json.loads(response.data)
        assert "models" in data
        assert "capabilities" in data
        assert "families" in data
        assert "server_results" in data


class TestNormalizeUrl:
    """Tests for URL normalization."""

    def test_empty_url(self):
        """Test empty URL returns empty string."""
        assert normalize_url("") == ""
        assert normalize_url("   ") == ""

    def test_adds_http_prefix(self):
        """Test that http:// is added when missing."""
        assert normalize_url("localhost:11434") == "http://localhost:11434"

    def test_preserves_https(self):
        """Test that https:// is preserved."""
        assert normalize_url("https://example.com") == "https://example.com"

    def test_removes_trailing_slash(self):
        """Test that trailing slash is removed."""
        assert normalize_url("http://localhost:11434/") == "http://localhost:11434"

    def test_strips_whitespace(self):
        """Test that whitespace is stripped."""
        assert normalize_url("  http://localhost:11434  ") == "http://localhost:11434"


class TestFormatSize:
    """Tests for size formatting."""

    def test_bytes(self):
        """Test formatting bytes."""
        assert format_size(500) == "500.0 B"

    def test_kilobytes(self):
        """Test formatting kilobytes."""
        assert format_size(1024) == "1.0 KB"

    def test_megabytes(self):
        """Test formatting megabytes."""
        assert format_size(1024 * 1024) == "1.0 MB"

    def test_gigabytes(self):
        """Test formatting gigabytes."""
        assert format_size(1024 * 1024 * 1024) == "1.0 GB"

    def test_terabytes(self):
        """Test formatting terabytes."""
        assert format_size(1024 * 1024 * 1024 * 1024) == "1.0 TB"


class TestGetMaxWorkers:
    """Tests for worker calculation."""

    @patch("os.cpu_count")
    def test_auto_workers(self, mock_cpu_count):
        """Test automatic worker calculation."""
        mock_cpu_count.return_value = 8
        workers = get_max_workers()
        assert 1 <= workers <= 8

    @patch("os.cpu_count")
    def test_handles_none_cpu_count(self, mock_cpu_count):
        """Test handling when cpu_count returns None."""
        mock_cpu_count.return_value = None
        workers = get_max_workers()
        assert workers >= 1


class TestErrorHandlers:
    """Tests for error handlers."""

    def test_404_error(self, client):
        """Test 404 error handler."""
        response = client.get("/nonexistent-page")
        assert response.status_code == 404
        data = json.loads(response.data)
        assert "error" in data
