# =========================
# Builder stage
# =========================
FROM ghcr.io/astral-sh/uv:python3.13-bookworm AS builder

WORKDIR /app

ENV UV_PROJECT_ENVIRONMENT=/app/.venv

# Copy manifests first — enables layer caching for dependencies
COPY pyproject.toml uv.lock /app/
RUN uv sync --frozen --no-dev

# Copy source after deps are installed
COPY . /app/


# =========================
# Runtime stage (hardened)
# =========================
FROM python:3.13-slim-bookworm AS runtime

WORKDIR /app

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    APP_ENV=production \
    PATH="/app/.venv/bin:$PATH"

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN useradd --create-home --uid 10001 appuser

# Copy venv and only the app source — not the whole repo
COPY --from=builder --chown=appuser:appuser /app/.venv /app/.venv
COPY --from=builder --chown=appuser:appuser /app/main.py /app/main.py
COPY --from=builder --chown=appuser:appuser /app/api /app/api
COPY --from=builder --chown=appuser:appuser /app/core /app/core
COPY --from=builder --chown=appuser:appuser /app/db /app/db
COPY --from=builder --chown=appuser:appuser /app/models /app/models
COPY --from=builder --chown=appuser:appuser /app/schemas /app/schemas
COPY --from=builder --chown=appuser:appuser /app/services /app/services

# Pre-create writable directories the app needs at runtime
RUN mkdir -p /app/data && chown -R appuser:appuser /app/data

USER appuser

EXPOSE 8000

CMD ["/app/.venv/bin/python", "-m", "uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
