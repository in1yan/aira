from fastapi import APIRouter

from app.api.v1.endpoints import auth, cards, detect, health

api_router = APIRouter()

api_router.include_router(
    health.router,
    tags=["health"],
)
api_router.include_router(
    auth.router,
    prefix="/auth",
    tags=["auth"],
)
api_router.include_router(
    cards.router,
    prefix="/cards",
    tags=["cards"],
)
api_router.include_router(
    detect.router,
    prefix="/detect",
    tags=["detect"],
)
