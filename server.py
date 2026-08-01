#!/usr/bin/env python3
"""
Simple static file server for PawPrint Flutter web app on Railway.
Serves index.html for all routes (Flutter SPA routing).
"""
import os
import http.server
import socketserver

PORT = int(os.environ.get("PORT", 8080))
DIRECTORY = os.path.dirname(os.path.abspath(__file__))


class SPAHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=DIRECTORY, **kwargs)

    def do_GET(self):
        # Try exact file first
        path = os.path.join(DIRECTORY, self.path.lstrip("/"))
        if os.path.isfile(path):
            return super().do_GET()

        # Fallback to index.html (Flutter SPA routing)
        index_path = os.path.join(DIRECTORY, "index.html")
        if os.path.isfile(index_path):
            self.path = "/index.html"
            return super().do_GET()

        # 404
        self.send_response(404)
        self.end_headers()
        self.wfile.write(b"404 Not Found")

    def log_message(self, format, *args):
        print(f"[PawPrint] {args[0]}")


if __name__ == "__main__":
    with socketserver.TCPServer(("", PORT), SPAHandler) as httpd:
        print(f"[PawPrint] Serving on port {PORT} from {DIRECTORY}")
        httpd.serve_forever()
