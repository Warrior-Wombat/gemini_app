from fastapi import APIRouter, HTTPException, Header
from pydantic import BaseModel
from firebase_admin import auth as firebase_auth
from app.services.config import db

router = APIRouter()

class User(BaseModel):
    email: str

class UserInDB(User):
    user_id: str

@router.post("/register", response_model=UserInDB)
async def register(user: User):
    try:
        # Create the user in Firebase Authentication
        user_record = firebase_auth.create_user(
            email=user.email,
            password=user.password
        )
        
        user_data = {
            "email": user.email,
        }

        # Store user data in Firestore with the UID as the document ID
        db.collection('users').document(user_record.uid).set(user_data)
        
        return UserInDB(**user_data, user_id=user_record.uid)
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

# not really necessary since firebase handles a bunch of the authentication, but good for uuid validation
@router.post("/login", response_model=UserInDB)
async def login(id_token: str = Header(None)):
    try:
        decoded_token = firebase_auth.verify_id_token(id_token)
        uid = decoded_token['uid']

        user_doc = db.collection('users').document(uid).get()
        if not user_doc.exists:
            raise HTTPException(status_code=404, detail="User not found")
        
        user_data = user_doc.to_dict()
        return UserInDB(**user_data, user_id=uid)
    except Exception as e:
        raise HTTPException(status_code=401, detail=str(e))

@router.get("/users/me", response_model=UserInDB)
async def read_users_me(id_token: str = Header(None)):
    try:
        decoded_token = firebase_auth.verify_id_token(id_token)
        uid = decoded_token['uid']

        user_doc = db.collection('users').document(uid).get()
        if not user_doc.exists:
            raise HTTPException(status_code=404, detail="User not found")
        
        user_data = user_doc.to_dict()
        return UserInDB(**user_data, user_id=uid)
    except Exception as e:
        raise HTTPException(status_code=401, detail=str(e))
