"""
WSGI entry point for production deployment.
Use with gunicorn, uWSGI, or other WSGI servers.

Examples:
    gunicorn wsgi:app
    gunicorn -w 4 -b 0.0.0.0:5000 wsgi:app
    uwsgi --http :5000 --wsgi-file wsgi.py --callable app
"""

from app import app

if __name__ == "__main__":
    app.run()
