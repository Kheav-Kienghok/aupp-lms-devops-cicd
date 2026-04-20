from prometheus_client import CollectorRegistry, Counter

registry = CollectorRegistry()

REQUEST_COUNT = Counter(
    "aupp_api_requests_total",
    "Total API Requests",
    ["method", "endpoint"],
    registry=registry,
)


def track_request(method: str, endpoint: str) -> None:
    REQUEST_COUNT.labels(method=method, endpoint=endpoint).inc()
