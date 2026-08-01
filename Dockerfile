# ── Stage 1: Build Flutter web app ───────────────────────────────────────
FROM python:3.12-slim AS builder

RUN apt-get update && apt-get install -y curl git unzip xz-utils zip libglu1-mesa --no-install-recommends && \
    rm -rf /var/lib/apt/lists/*

# Install Flutter SDK (exact version for this project)
ARG FLUTTER_VERSION=3.24.0
ENV FLUTTER_VERSION=${FLUTTER_VERSION}
RUN curl -fsSL "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" | tar xJ -C /opt && \
    ln -s /opt/flutter/bin/flutter /usr/local/bin/flutter && \
    ln -s /opt/flutter/bin/dart /usr/local/bin/dart

ENV PATH="/opt/flutter/bin:${PATH}"
ENV FLUTTER_ROOT=/opt/flutter

WORKDIR /app

# Copy Flutter project
COPY app/ ./app/
WORKDIR /app/app

# Pre-cache dependencies (layer-cacheable)
COPY app/pubspec.yaml ./pubspec.yaml
RUN flutter pub get

# Build web (outputs to build/web/)
RUN flutter build web --release --no-tree-shake-icons

# ── Stage 2: Serve with Python ───────────────────────────────────────────
FROM python:3.12-slim

WORKDIR /app

# Copy built web output from stage 1
COPY --from=builder /app/app/build/web/ ./

# Railway injects PORT env var; default to 8080
ENV PORT=8080
EXPOSE 8080

# Use Python's built-in HTTP server — handles Flutter SPA routing fine
# Railway's load balancer handles HTTPS termination
CMD ["python3", "-m", "http.server", "8080"]
