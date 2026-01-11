# 🦙 Ollama Model Explorer

A modern, responsive web application for exploring and filtering AI models across multiple Ollama servers.

![Python](https://img.shields.io/badge/python-3.8+-blue.svg)
![Flask](https://img.shields.io/badge/flask-2.3+-green.svg)
![License](https://img.shields.io/badge/license-MIT-blue.svg)

## Project Structure

```
ollama-models-explorer/
├── app.py
├── config.py
├── wsgi.py
├── static/
│   ├── script.js
│   └── style.css
├── templates/
│   └── index.html
├── scripts/
│   ├── run.sh
│   ├── run.bat
│   └── run.ps1
├── tests/
│   ├── __init__.py
│   └── test_app.py
├── .env.example
├── .gitignore
├── Dockerfile
├── docker-compose.yml
├── Makefile
├── pyproject.toml
├── requirements.txt
├── requirements-dev.txt
├── LICENSE
└── README.md
```


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