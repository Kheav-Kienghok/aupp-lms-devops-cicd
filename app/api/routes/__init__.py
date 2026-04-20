from api.routes.auth import router as auth_router
from api.routes.items import router as items_router
from api.routes.system import router as system_router

__all__ = ["auth_router", "items_router", "system_router"]
