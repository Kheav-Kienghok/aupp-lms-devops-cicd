from fastapi import FastAPI

from api.routes import auth_router, items_router, system_router
from core.config import is_docs_enabled
from db.database import init_db

docs_enabled = is_docs_enabled()

app = FastAPI(
    title="AUPP LMS API",
    docs_url="/docs" if docs_enabled else None,
    redoc_url="/redoc" if docs_enabled else None,
    openapi_url="/openapi.json" if docs_enabled else None,
)

app.include_router(system_router)
app.include_router(auth_router)
app.include_router(items_router)


@app.on_event("startup")
def on_startup() -> None:
    init_db()


if __name__ == "__main__":
    import uvicorn

    uvicorn.run("main:app", host="0.0.0.0", port=8000)
