from fastapi import APIRouter, UploadFile, File, Depends
from typing import List
from ..classes.user_session import UserSession
from app.services.config import db
from io import BytesIO

router = APIRouter()

def get_user_session(user_id: str):
    return UserSession(user_id)

@router.post("/transcribe", response_model=List[str])
async def transcribe_audio(user_id: str, audio: UploadFile = File(...), session: UserSession = Depends(get_user_session)):
    audio_data = await audio.read()
    transcription = session.predictor.transcribe_audio(BytesIO(audio_data))
    return transcription
