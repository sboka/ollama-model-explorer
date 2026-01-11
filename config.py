"""
Application configuration management.
Supports environment variables and .env files.
"""

import os
from pathlib import Path

# Try to load .env file if python-dotenv is available
try:
    from dotenv import load_dotenv

    env_path = Path(__file__).parent / ".env"
    if env_path.exists():
        load_dotenv(env_path)
except ImportError:
    pass


class Config:
    """Base configuration."""

    # Flask settings
    SECRET_KEY = os.getenv("SECRET_KEY", "dev-secret-key-change-in-production")

    # Server settings
    HOST = os.getenv("HOST", "0.0.0.0")
    PORT = int(os.getenv("PORT", 5000))
    DEBUG = os.getenv("DEBUG", "false").lower() in ("true", "1", "yes")

    # Request settings
    REQUEST_TIMEOUT = int(os.getenv("REQUEST_TIMEOUT", 15))
    MAX_WORKERS = int(os.getenv("MAX_WORKERS", 0))  # 0 = auto

    # CORS settings
    CORS_ORIGINS = os.getenv("CORS_ORIGINS", "*")

    # Logging
    LOG_LEVEL = os.getenv("LOG_LEVEL", "INFO")
    LOG_FORMAT = os.getenv(
        "LOG_FORMAT", "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
    )


class DevelopmentConfig(Config):
    """Development configuration."""

    DEBUG = True
    LOG_LEVEL = "DEBUG"


class ProductionConfig(Config):
    """Production configuration."""

    DEBUG = False
    LOG_LEVEL = "WARNING"


class TestingConfig(Config):
    """Testing configuration."""

    TESTING = True
    DEBUG = True


def get_config():
    """Get configuration based on environment."""
    env = os.getenv("FLASK_ENV", "production").lower()
    configs = {
        "development": DevelopmentConfig,
        "production": ProductionConfig,
        "testing": TestingConfig,
    }
    return configs.get(env, ProductionConfig)()
