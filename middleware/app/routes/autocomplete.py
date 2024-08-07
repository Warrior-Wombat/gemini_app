from fastapi import APIRouter, HTTPException, Depends, File, UploadFile
from pydantic import BaseModel
from io import BytesIO
from ..classes.user_session import UserSession

router = APIRouter()

class UserRequest(BaseModel):
    user_id: str
    input_text: str

# different classes to differentiate between p1 and p2 of conversation
class LabelResponseRequest(BaseModel):
    user_id: str
    transcription: str

class ImageRequest(BaseModel):
    user_id: str
    image_path: str

def get_user_session(user_id: str):
    return UserSession.get_user_session(user_id)

@router.post("/user_input")
def user_input(request: UserRequest):
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
def handle_image_input(request: ImageRequest):
    session = UserSession.get_user_session(request.user_id)
    session.handle_image_input(request.image_path)
    return {"message": "Image handled successfully"}

@router.post("/end_session")
def end_session(request: UserRequest):
    session = UserSession.get_user_session(request.user_id)
    session.save_user_data()
    return {"message": "User data saved and session ended"}

@router.post("/label_response")
def label_response(request: LabelResponseRequest):
    session = UserSession.get_user_session(request.user_id)
    response = session.label_response(request.transcription)
    # return predictions from processing
    return {"predictions": response['predictions']}
