from fastapi import APIRouter, Depends
from typing import List, Tuple
from ..classes.user_session import UserSession
from app.services.config import db

router = APIRouter()

def get_user_session(user_id: str):
    return UserSession(user_id)

@router.get("/predictions", response_model=Tuple[List[str], List[str]])
async def get_predictions(user_id: str, current_input: str, session: UserSession = Depends(get_user_session)):
    return session.get_predictions(current_input)
