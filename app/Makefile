APP_MODULE = main:app
HOST = 0.0.0.0
PORT = 8000

.PHONY: install run lint lint-fix format format-check check clean

install:
	uv sync --dev

run:
	uv run uvicorn $(APP_MODULE) --reload --host $(HOST) --port $(PORT)

lint:
	uv run ruff check .

lint-fix:
	uv run ruff check . --fix

format:
	uv run black .

format-check:
	uv run black --check .

check: lint format-check

clean:
	find . -type d -name "__pycache__" -prune -exec rm -rf {} +
	find . -type d -name ".ruff_cache" -prune -exec rm -rf {} +
	find . -type f -name "*.pyc" -delete

