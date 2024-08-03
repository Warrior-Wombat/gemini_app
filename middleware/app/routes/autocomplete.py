from fastapi import APIRouter, Depends, HTTPException, Query
from typing import List
from app.services.user_session import User
from app.services.config import db
from ..services.gemini_prediction import GeminiPredictor

router = APIRouter()

def get_user_session(user_id: str):
    return User(user_id)

@router.get("/autocomplete", response_model=List[str])
async def get_autocomplete_predictions(
    user_id: str = Query(..., description="User ID"),
    last_word: str = Query('', description="Last word typed by the user"),
    session: User = Depends(get_user_session)
):
    try:
        predictor = GeminiPredictor()
        predictions, _ = predictor.get_predictions([last_word], user_id, is_new_sentence=False)
        return predictions
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
