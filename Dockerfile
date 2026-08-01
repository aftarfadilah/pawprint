# Multi-stage Dockerfile for PawPrint Flutter Web App on Railway.
# Railway builds this image, then runs the `CMD` to serve the built web app.

# ── Stage 1: Build ──────────────────────────────────────────────────────
FROM ghcr.io/nickbild/flutter:latest AS build

WORKDIR /app

# Copy pubspec and resolve deps first (layer-cached if only source changes)
COPY pubspec.yaml .
RUN flutter pub get

# Copy source and build
COPY . .
RUN flutter build web --release --no-tree-shake-icons

# ── Stage 2: Serve ──────────────────────────────────────────────────────
FROM python:3.12-slim

WORKDIR /app

# Copy built web assets from stage 1
COPY --from=build /app/build/web ./

# Railway expects PORT env var; default to 8080
ENV PORT=8080

# Python's built-in HTTP server handles Flutter's SPA routing fine,
# and Railway's load balancer handles HTTPS termination.
EXPOSE 8080

CMD ["python3", "-m", "http.server", "8080"]
