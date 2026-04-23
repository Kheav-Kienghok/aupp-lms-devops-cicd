from fastapi import APIRouter
from fastapi.responses import PlainTextResponse
from prometheus_client import CONTENT_TYPE_LATEST, generate_latest

from core.metrics import registry, track_request

router = APIRouter()


@router.get("/")
def root() -> dict[str, str]:
    track_request("GET", "/")
    return {"message": "AUPP LMS backend is running v2"}


@router.get("/health")
def health() -> dict[str, str]:
    track_request("GET", "/health")
    return {"status": "ok"}


@router.get("/metrics")
def metrics() -> PlainTextResponse:
    track_request("GET", "/metrics")
    return PlainTextResponse(
        generate_latest(registry).decode("utf-8"),
        media_type=CONTENT_TYPE_LATEST,
    )
