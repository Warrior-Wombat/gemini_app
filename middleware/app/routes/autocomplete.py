from fastapi import APIRouter, HTTPException, Depends, File, UploadFile
from pydantic import BaseModel
from io import BytesIO
from ..classes.user_session import UserSession

router = APIRouter()

class UserInputRequest(BaseModel):
    user_id: str
    input_text: str

class ImageInputRequest(BaseModel):
    user_id: str
    image_path: str

def get_user_session(user_id: str):
    return UserSession.get_user_session(user_id)

@router.post("/user_input")
def user_input(request: UserInputRequest):
    session = UserSession.get_user_session(request.user_id)
    if request.input_text.lower() == 'image':
        return {"message": "Please use /autocomplete/image_input for image processing."}
    else:
        gemini_predictions, usage_based_predictions = session.get_predictions(request.input_text)
        session.update_model(request.input_text)
        return {
            "gemini_predictions": gemini_predictions,
            "usage_based_predictions": usage_based_predictions
        }

@router.post("/image_input")
def handle_image_input(request: ImageInputRequest):
    session = UserSession.get_user_session(request.user_id)
    session.handle_image_input(request.image_path)
    return {"message": "Image handled successfully"}

@router.post("/end_session")
def end_session(request: UserInputRequest):
    session = UserSession.get_user_session(request.user_id)
    session.save_user_data()
    return {"message": "User data saved and session ended"}

@router.post("/listen_audio")
async def listen_audio(user_id: str, file: UploadFile = File(...)):
    session = UserSession.get_user_session(user_id)
    audio_data = await file.read()
    audio_buffer = BytesIO(audio_data)
    transcription = session.predictor.transcribe_audio(audio_buffer)
    
    if transcription:
        session.update_model(transcription)
        return {"transcription": transcription, "message": "Audio processed successfully"}
    else:
        raise HTTPException(status_code=400, detail="Failed to transcribe audio")