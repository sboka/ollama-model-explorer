#!/usr/bin/env python3
"""
Ollama Model Explorer - A web application for exploring and filtering
models across multiple Ollama servers.
"""

import json
import logging
import os
import sys
import urllib.request
import urllib.error
from concurrent.futures import ThreadPoolExecutor, as_completed
from typing import List, Dict, Any, Optional

from flask import Flask, render_template, request, jsonify

from config import get_config

# Initialize configuration
config = get_config()

# Configure logging
logging.basicConfig(
    level=getattr(logging, config.LOG_LEVEL),
    format=config.LOG_FORMAT,
    handlers=[logging.StreamHandler(sys.stdout)],
)
logger = logging.getLogger(__name__)

# Initialize Flask app
app = Flask(__name__)
app.config.from_object(config)


def get_max_workers() -> int:
    """Calculate the number of worker threads."""
    if config.MAX_WORKERS > 0:
        return config.MAX_WORKERS
    cpu_count = os.cpu_count() or 1
    return max(1, min(cpu_count, 8))


def http_get_json(url: str, timeout: Optional[int] = None) -> Dict[str, Any]:
    """Perform HTTP GET request and return JSON response."""
    timeout = timeout or config.REQUEST_TIMEOUT
    req = urllib.request.Request(
        url, method="GET", headers={"User-Agent": "OllamaModelExplorer/1.0"}
    )
    with urllib.request.urlopen(req, timeout=timeout) as resp:
        return json.loads(resp.read().decode("utf-8"))


def http_post_json(
    url: str, payload: Dict[str, Any], timeout: Optional[int] = None
) -> Dict[str, Any]:
    """Perform HTTP POST request with JSON payload and return JSON response."""
    timeout = timeout or config.REQUEST_TIMEOUT
    data = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(
        url,
        data=data,
        headers={
            "Content-Type": "application/json",
            "User-Agent": "OllamaModelExplorer/1.0",
        },
        method="POST",
    )
    with urllib.request.urlopen(req, timeout=timeout) as resp:
        return json.loads(resp.read().decode("utf-8"))


def get_all_models(base_url: str) -> List[Dict[str, Any]]:
    """Get all models from an Ollama server."""
    tags = http_get_json(f"{base_url}/api/tags")
    return tags.get("models", [])


def get_model_details(base_url: str, model_name: str) -> Dict[str, Any]:
    """Get detailed information for a specific model."""
    info = http_post_json(
        f"{base_url}/api/show",
        {"model": model_name},
    )
    return info


def format_size(size_bytes: int) -> str:
    """Format bytes to human readable string."""
    for unit in ["B", "KB", "MB", "GB", "TB"]:
        if size_bytes < 1024:
            return f"{size_bytes:.1f} {unit}"
        size_bytes /= 1024
    return f"{size_bytes:.1f} PB"


def inspect_model(base_url: str, model_info: Dict[str, Any]) -> Dict[str, Any]:
    """Inspect a model and return its full details."""
    model_name = model_info.get("name", "")
    try:
        details = get_model_details(base_url, model_name)
        model_details = details.get("details", {})
        model_info_data = details.get("model_info", {})

        # Extract context length from model_info
        context_length = None
        for key, value in model_info_data.items():
            if "context_length" in key.lower():
                context_length = value
                break

        return {
            "name": model_name,
            "server": base_url,
            "size": model_info.get("size", 0),
            "size_formatted": format_size(model_info.get("size", 0)),
            "modified_at": model_info.get("modified_at", ""),
            "digest": (
                model_info.get("digest", "")[:12] if model_info.get("digest") else ""
            ),
            "capabilities": details.get("capabilities", []),
            "parameters": model_details.get("parameter_size", ""),
            "quantization": model_details.get("quantization_level", ""),
            "family": model_details.get("family", ""),
            "format": model_details.get("format", ""),
            "parent_model": model_details.get("parent_model", ""),
            "context_length": context_length,
            "context_length_formatted": context_length / 1024,
        }
    except Exception as e:
        logger.warning(f"Failed to inspect model '{model_name}': {e}")
        return {
            "name": model_name,
            "server": base_url,
            "size": model_info.get("size", 0),
            "size_formatted": format_size(model_info.get("size", 0)),
            "modified_at": model_info.get("modified_at", ""),
            "capabilities": [],
            "error": str(e),
        }


def fetch_models_from_server(base_url: str) -> Dict[str, Any]:
    """Fetch all models and their details from a single server."""
    try:
        logger.info(f"Fetching models from {base_url}")
        models = get_all_models(base_url)
        results = []

        max_workers = get_max_workers()

        with ThreadPoolExecutor(max_workers=max_workers) as executor:
            future_map = {
                executor.submit(inspect_model, base_url, model): model
                for model in models
            }

            for future in as_completed(future_map):
                try:
                    result = future.result()
                    results.append(result)
                except Exception as e:
                    model = future_map[future]
                    logger.warning(f"Failed to process model: {e}")
                    results.append(
                        {
                            "name": model.get("name", "unknown"),
                            "server": base_url,
                            "capabilities": [],
                            "error": str(e),
                        }
                    )

        logger.info(f"Found {len(results)} models on {base_url}")
        return {"server": base_url, "models": results, "success": True}

    except urllib.error.URLError as e:
        error_msg = f"Connection failed: {str(e.reason)}"
        logger.error(f"Failed to connect to {base_url}: {error_msg}")
        return {"server": base_url, "error": error_msg, "success": False}

    except Exception as e:
        logger.error(f"Error fetching from {base_url}: {e}")
        return {"server": base_url, "error": str(e), "success": False}


def normalize_url(url: str) -> str:
    """Normalize server URL."""
    url = url.strip().rstrip("/")
    if not url:
        return ""
    if not url.startswith(("http://", "https://")):
        url = f"http://{url}"
    return url


# Routes


@app.route("/")
def index():
    """Render the main page."""
    return render_template("index.html")


@app.route("/health")
def health():
    """Health check endpoint."""
    return jsonify({"status": "healthy", "version": "1.0.0"})


@app.route("/api/fetch", methods=["POST"])
def fetch_models():
    """API endpoint to fetch models from multiple servers."""
    data = request.get_json()

    if not data:
        return jsonify({"error": "Invalid JSON payload"}), 400

    servers = data.get("servers", [])

    if not servers:
        return jsonify({"error": "No servers provided"}), 400

    # Normalize and deduplicate servers
    normalized_servers = []
    seen = set()
    for server in servers:
        if not isinstance(server, str):
            continue
        normalized = normalize_url(server)
        if normalized and normalized not in seen:
            normalized_servers.append(normalized)
            seen.add(normalized)

    if not normalized_servers:
        return jsonify({"error": "No valid servers provided"}), 400

    all_models = []
    server_results = []
    all_capabilities = set()
    all_families = set()

    # Fetch from all servers in parallel
    max_workers = min(len(normalized_servers), get_max_workers())

    with ThreadPoolExecutor(max_workers=max_workers) as executor:
        future_map = {
            executor.submit(fetch_models_from_server, server): server
            for server in normalized_servers
        }

        for future in as_completed(future_map):
            result = future.result()
            server_results.append(
                {
                    "server": result["server"],
                    "success": result["success"],
                    "error": result.get("error"),
                    "model_count": len(result.get("models", [])),
                }
            )

            if result["success"]:
                for model in result.get("models", []):
                    all_models.append(model)
                    all_capabilities.update(model.get("capabilities", []))
                    if model.get("family"):
                        all_families.add(model["family"])

    return jsonify(
        {
            "models": all_models,
            "capabilities": sorted(list(all_capabilities)),
            "families": sorted(list(all_families)),
            "server_results": server_results,
        }
    )


# Error handlers


@app.errorhandler(404)
def not_found(error):
    """Handle 404 errors."""
    return jsonify({"error": "Not found"}), 404


@app.errorhandler(500)
def internal_error(error):
    """Handle 500 errors."""
    logger.error(f"Internal server error: {error}")
    return jsonify({"error": "Internal server error"}), 500


def main():
    """Main entry point for the application."""
    import argparse

    parser = argparse.ArgumentParser(
        description="Ollama Model Explorer Web Application",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    parser.add_argument("--host", default=config.HOST, help="Host to bind to")
    parser.add_argument("--port", type=int, default=config.PORT, help="Port to bind to")
    parser.add_argument(
        "--debug", action="store_true", default=config.DEBUG, help="Enable debug mode"
    )

    args = parser.parse_args()

    logger.info(f"Starting Ollama Model Explorer on http://{args.host}:{args.port}")
    app.run(host=args.host, port=args.port, debug=args.debug)


if __name__ == "__main__":
    main()
