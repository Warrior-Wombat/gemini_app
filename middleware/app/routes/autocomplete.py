from fastapi import APIRouter, Depends
from typing import List
from app.services.user_session import User
from app.services.config import db

router = APIRouter()

def get_user_session(user_id: str):
    return User(user_id)

@router.get("/autocomplete", response_model=List[str])
async def get_autocomplete_predictions(user_id: str, last_word: str, session: User = Depends(get_user_session)):
    return session.predictor.get_usage_based_predictions(last_word)
