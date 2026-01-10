# Ollama Model Explorer

A modern web application for exploring and filtering models across multiple Ollama servers.

## Project Structure

```
ollama-models-explorer/
├── app.py
├── static/
│   ├── script.js
│   └── style.css
├── templates/
│   └── index.html
├── README.md
└── requirements.txt
```

## Files

### `requirements.txt`

```
flask>=2.3.0
```

### `app.py`

```python
#!/usr/bin/env python3
"""
Ollama Model Explorer - A web application for exploring and filtering
models across multiple Ollama servers.
"""

if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(description="Ollama Model Explorer Web Application")
    parser.add_argument("--host", default="0.0.0.0", help="Host to bind to")
    parser.add_argument("--port", type=int, default=5000, help="Port to bind to")
    parser.add_argument("--debug", action="store_true", help="Enable debug mode")
    
    args = parser.parse_args()
    
    print(f"Starting Ollama Model Explorer on http://{args.host}:{args.port}")
    app.run(host=args.host, port=args.port, debug=args.debug)
```

### `templates/index.html`

## Usage

### Installation

```bash
# Create project directory
mkdir ollama-explorer
cd ollama-explorer

# Create virtual environment (optional but recommended)
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install flask

# Create the directory structure and files as shown above
mkdir templates
# Copy app.py to the root directory
# Copy index.html to templates/
```

### Running the Application

```bash
# Basic run
python app.py

# With custom host and port
python app.py --host 127.0.0.1 --port 8080

# With debug mode
python app.py --debug
```

Then open your browser to `http://localhost:5000`

## Features

1. **Multi-Server Support**: Add multiple Ollama server URLs and fetch models from all of them
2. **Dynamic Capability Filtering**: Filter by any capability the models report (completion, vision, tools, embedding, insert, or any future capability)
3. **Family Filtering**: Filter by model family (llama, qwen, gemma, etc.)
4. **Server Filtering**: Filter by source server
5. **Search**: Full-text search on model names
6. **Match Mode Toggle**: Switch between "Any" (OR) and "All" (AND) matching for capability filters
7. **Sorting**: Sort by name, size, or modification date
8. **View Toggle**: Switch between grid and list views
9. **Responsive Design**: Works on desktop and mobile devices
10. **Real-time Filtering**: All filters apply instantly without page reload

## Screenshot Preview

The application features a modern dark theme with:
- Gradient header branding
- Card-based model display with capability tags
- Pill-style filter chips
- Smooth hover animations
- Color-coded capability badges
- Responsive design