from fastapi import APIRouter, Depends
from typing import List, Tuple
from app.services.user_session import User
from app.config import db

router = APIRouter()

def get_user_session(user_id: str):
    return User(user_id)

@router.get("/predictions", response_model=Tuple[List[str], List[str]])
async def get_predictions(user_id: str, current_input: str, session: User = Depends(get_user_session)):
    return session.get_predictions(current_input)
