"""
Simple Python HTTP server for serving Flutter web build.
Railway sets PORT env var; this script respects it.
"""
import http.server
import os

PORT = int(os.environ.get("PORT", 8080))
DIRECTORY = os.path.dirname(os.path.abspath(__file__)) or "."

class SPAHandler(http.server.SimpleHTTPRequestHandler):
    """Serves index.html for any path that doesn't match a file — enables Flutter routing."""

    def end_headers(self):
        # Railway injects these headers automatically; we just add ours
        self.send_header("X-Content-Type-Options", "nosniff")
        super().end_headers()

    def do_GET(self):
        # Try exact file first
        path = os.path.join(DIRECTORY, self.path.lstrip("/"))
        if os.path.isfile(path):
            return super().do_GET()

        # Fallback to index.html for Flutter routing
        index = os.path.join(DIRECTORY, "index.html")
        if os.path.isfile(index):
            self.path = "/index.html"
            return super().do_GET()

        # 404
        self.send_response(404)
        self.send_header("Content-Type", "text/plain")
        self.end_headers()
        self.wfile.write(b"404 Not Found")

    def log_message(self, format, *args):
        # Keep logs quiet in production
        pass


if __name__ == "__main__":
    os.chdir(DIRECTORY)
    print(f"Serving {DIRECTORY} on port {PORT}")
    with http.server.HTTPServer(("", PORT), SPAHandler) as httpd:
        httpd.serve_forever()
