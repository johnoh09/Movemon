# app/api/v1/routes.py
from fastapi import APIRouter
from app.routers.sports import router as sports
from app.routers.workouts import router as workouts
from app.routers.goals import router as goals
from app.routers.characters import router as characters
from app.routers.user_logs import router as user_logs
from app.routers.reports import router as reports
from app.routers.users import router as users
from app.routers.auth import router as auth


api = APIRouter()

@api.get("/health", tags=["health"])
async def health():
    return {"status": "ok"}

api.include_router(sports)
api.include_router(workouts)
api.include_router(goals)
api.include_router(characters)
api.include_router(user_logs)
api.include_router(reports)
api.include_router(users)
api.include_router(auth)
