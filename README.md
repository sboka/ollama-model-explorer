# 🦙 Ollama Model Explorer

A modern, responsive web application for exploring and filtering AI models across multiple Ollama servers.

![Python](https://img.shields.io/badge/python-3.8+-blue.svg)
![Flask](https://img.shields.io/badge/flask-2.3+-green.svg)
![License](https://img.shields.io/badge/license-MIT-blue.svg)

## ✨ Features

- **Multi-Server Support**: Connect to multiple Ollama servers simultaneously
- **Real-time Filtering**: Filter models by capabilities, family, and server
- **Smart Search**: Full-text search across model names
- **Capability Matching**: Toggle between AND/OR matching for capabilities
- **Responsive Design**: Works on desktop, tablet, and mobile
- **Dark Theme**: Modern, eye-friendly dark interface
- **Persistent Settings**: Server list saved across browser sessions
- **Grid/List Views**: Switch between card and list layouts
- **Sorting Options**: Sort by name, size, or modification date

## 🚀 Quick Start

### Prerequisites

- Python 3.8 or higher
- One or more Ollama servers running

### Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/ollama-model-explorer.git
cd ollama-model-explorer

# Create virtual environment
python -m venv .venv

# Activate virtual environment
# On Linux/macOS:
source .venv/bin/activate
# On Windows (CMD):
.venv\Scripts\activate.bat
# On Windows (PowerShell):
.venv\Scripts\Activate.ps1

# Install dependencies
pip install -r requirements.txt
```

### Running the Application

#### Development Mode

```bash
# Using Python directly
python app.py --debug

# Using the run script (Linux/macOS)
./scripts/run.sh dev

# Using the run script (Windows CMD)
scripts\run.bat dev

# Using the run script (Windows PowerShell)
.\scripts\run.ps1 dev

# Using Make
make dev
```

#### Production Mode

```bash
# Linux/macOS (with Gunicorn)
gunicorn -w 4 -b 0.0.0.0:5000 wsgi:app

# Windows (with Waitress)
waitress-serve --host=0.0.0.0 --port=5000 wsgi:app

# Using run scripts
./scripts/run.sh prod      # Linux/macOS
scripts\run.bat prod       # Windows CMD
.\scripts\run.ps1 prod     # Windows PowerShell

# Using Make
make prod
```

### Using Docker

```bash
# Build the image
docker build -t ollama-model-explorer .

# Run the container
docker run -d -p 5000:5000 --name ollama-explorer ollama-model-explorer

# Or use Docker Compose
docker-compose up -d
```

## ⚙️ Configuration

Configuration can be done via environment variables or a `.env` file:

```bash
# Copy the example environment file
cp .env.example .env

# Edit the configuration
nano .env
```

### Available Options

| Variable | Default | Description |
|----------|---------|-------------|
| `FLASK_ENV` | `production` | Environment: `development`, `production`, `testing` |
| `HOST` | `0.0.0.0` | Host to bind to |
| `PORT` | `5000` | Port to bind to |
| `DEBUG` | `false` | Enable debug mode |
| `SECRET_KEY` | `dev-secret...` | Flask secret key (change in production!) |
| `REQUEST_TIMEOUT` | `15` | Timeout for Ollama API requests (seconds) |
| `MAX_WORKERS` | `0` | Max worker threads (0 = auto) |
| `LOG_LEVEL` | `INFO` | Logging level |

## 📖 Usage

1. Open your browser to `http://localhost:5000`
2. Add your Ollama server URLs (e.g., `http://localhost:11434`)
3. Click "Fetch Models" to retrieve available models
4. Use filters to narrow down the model list:
   - **Search**: Type to filter by model name
   - **Capabilities**: Filter by model capabilities (completion, vision, tools, etc.)
   - **Family**: Filter by model family (llama, mistral, etc.)
   - **Server**: Filter by source server
5. Toggle between "Any" and "All" matching for capabilities
6. Switch between grid and list views
7. Sort models by name, size, or modification date

## 🧪 Development

### Running Tests

```bash
# Install dev dependencies
pip install -r requirements-dev.txt

# Run tests
pytest

# Run tests with coverage
pytest --cov=. --cov-report=html

# Using Make
make test
```

### Code Quality

```bash
# Format code
make format

# Run linters
make lint
```

### Project Structure

```
ollama-model-explorer/
├── app.py              # Main Flask application
├── config.py           # Configuration management
├── wsgi.py             # WSGI entry point
├── static/
│   ├── script.js       # Frontend JavaScript
│   └── style.css       # Styles
├── templates/
│   └── index.html      # Main HTML template
├── scripts/
│   ├── run.sh          # Unix run script
│   ├── run.bat         # Windows CMD script
│   └── run.ps1         # PowerShell script
├── tests/
│   └── test_app.py     # Application tests
├── Dockerfile          # Docker configuration
├── docker-compose.yml  # Docker Compose configuration
├── Makefile            # Make commands
├── pyproject.toml      # Python project configuration
├── requirements.txt    # Production dependencies
└── requirements-dev.txt # Development dependencies
```

## 🔒 Security Considerations

- Change the `SECRET_KEY` in production
- Use HTTPS in production (configure via reverse proxy)
- Consider network isolation for Ollama servers
- Review CORS settings for your deployment

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [Ollama](https://ollama.ai/) for the amazing local LLM runtime
- [Flask](https://flask.palletsprojects.com/) for the web framework

---

## Summary

This production-ready setup includes:

1. **Configuration Management** (`config.py`) - Environment-based configuration with `.env` support
2. **WSGI Entry Point** (`wsgi.py`) - For production servers like Gunicorn/Waitress
3. **Cross-Platform Scripts** - Shell, Batch, and PowerShell scripts for all platforms
4. **Docker Support** - Multi-stage Dockerfile and docker-compose for containerization
5. **Testing** - Pytest-based test suite with coverage
6. **Code Quality** - Black, isort, flake8, mypy configurations
7. **Makefile** - Convenient commands for common tasks
8. **Proper Packaging** - `pyproject.toml` for modern Python packaging
9. **Documentation** - Comprehensive README with usage instructions
10. **Security** - Health checks, non-root Docker user, proper error handling
11. **Logging** - Configurable logging throughout the application

