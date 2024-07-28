from fastapi import APIRouter, UploadFile, File, Depends
from typing import List, Tuple
from app.services.user_session import User

router = APIRouter()

def get_user_session(user_id: str):
    return User(user_id)

@router.post("/summary", response_model=Tuple[str, List[str]])
async def summarize_image(user_id: str, image: UploadFile = File(...), session: User = Depends(get_user_session)):
    image_path = image.filename
    with open(image_path, "wb") as buffer:
        buffer.write(await image.read())
    return session.handle_image_input(image_path)
