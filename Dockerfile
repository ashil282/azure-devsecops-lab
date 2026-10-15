# syntax=docker/dockerfile:1

# ==========================================
# Stage 1: Build dependencies
# ==========================================
FROM python:3.14-slim AS builder

WORKDIR /build

# Install system build dependencies if any C-extensions are needed (optional, uncomment if required)
# RUN apt-get update && apt-get install -y --no-install-recommends build-essential

COPY app/requirements.txt .

# Install dependencies into a separate prefix directory for clean copying
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt


# ==========================================
# Stage 2: Runtime image
# ==========================================
FROM python:3.14-slim

# Prevent Python from writing pyc files and buffer stdout/stderr
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# Create a non-privileged user and group
RUN groupadd --system --gid 10001 app \
    && useradd --system --uid 10001 --gid app --no-create-home --shell /usr/sbin/nologin app

WORKDIR /app

# Copy installed python packages from the builder stage
COPY --from=builder /install /usr/local

# Copy application source code
COPY app/ ./

# Change ownership of the app directory to the non-root user
RUN chown -R 10001:10001 /app

# Switch to the non-root user
USER 10001:10001

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD ["python", "-c", "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8080/healthz', timeout=2)"]

ENTRYPOINT ["gunicorn", "--bind", "0.0.0.0:8080", "--workers", "2", "--worker-tmp-dir", "/dev/shm", "app:app"]
