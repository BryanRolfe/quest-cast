#!/usr/bin/env python3
"""Quest Cast Manager — lightweight container control panel."""

import http.server
import json
import os
import socket

CONTAINER = os.environ.get("MANAGED_CONTAINER", "quest-cast")
DOCKER_SOCKET = "/var/run/docker.sock"
PORT = 8081


def docker_request(method, path, timeout=30):
    """Send an HTTP request to the Docker daemon via Unix socket."""
    sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    sock.connect(DOCKER_SOCKET)
    sock.settimeout(timeout)

    request = f"{method} {path} HTTP/1.0\r\nHost: localhost\r\n\r\n"
    sock.sendall(request.encode())

    response = b""
    while True:
        try:
            chunk = sock.recv(4096)
            if not chunk:
                break
            response += chunk
        except socket.timeout:
            break
    sock.close()

    header_end = response.find(b"\r\n\r\n")
    if header_end == -1:
        return 500, ""

    status_line = response[: response.find(b"\r\n")].decode()
    status_code = int(status_line.split(" ")[1])
    body = response[header_end + 4 :].decode()

    return status_code, body


def get_container_status():
    """Get the current status of the managed container."""
    code, body = docker_request("GET", f"/containers/{CONTAINER}/json")
    if code == 200:
        try:
            return json.loads(body).get("State", {}).get("Status", "unknown")
        except (json.JSONDecodeError, KeyError):
            return "unknown"
    if code == 404:
        return "not found"
    return "error"


class Handler(http.server.BaseHTTPRequestHandler):
    def log_message(self, format, *args):
        pass

    def send_json(self, data, code=200):
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        self.wfile.write(json.dumps(data).encode())

    def do_GET(self):
        if self.path == "/api/status":
            self.send_json({"status": get_container_status()})
        else:
            self.send_response(200)
            self.send_header("Content-Type", "text/html")
            self.end_headers()
            with open("/app/index.html", "rb") as f:
                self.wfile.write(f.read())

    def do_POST(self):
        if self.path == "/api/start":
            docker_request("POST", f"/containers/{CONTAINER}/start")
            self.send_json({"status": get_container_status()})
        elif self.path == "/api/stop":
            docker_request("POST", f"/containers/{CONTAINER}/stop?t=5", timeout=15)
            self.send_json({"status": get_container_status()})
        else:
            self.send_json({"error": "not found"}, 404)


if __name__ == "__main__":
    server = http.server.HTTPServer(("0.0.0.0", PORT), Handler)
    print(f"[quest-cast-manager] Listening on port {PORT}")
    server.serve_forever()
