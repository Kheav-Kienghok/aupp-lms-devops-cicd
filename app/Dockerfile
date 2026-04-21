FROM ghcr.io/astral-sh/uv:python3.13-bookworm AS builder

WORKDIR /app

COPY . /app
RUN uv sync --frozen --no-dev

FROM python:3.13-slim-bookworm AS runtime

WORKDIR /app

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    APP_ENV=prod \
    PATH="/app/.venv/bin:$PATH"

RUN apt-get update \
    && apt-get upgrade -y \
    && rm -rf /var/lib/apt/lists/*

RUN useradd --create-home --uid 10001 appuser

COPY --from=builder --chown=appuser:appuser /app /app
RUN mkdir -p /app/data && chown -R appuser:appuser /app/data

USER appuser

EXPOSE 8000

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
