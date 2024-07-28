from fastapi import FastAPI, HTTPException, Depends, Header
from fastapi.security import OAuth2PasswordBearer
from pydantic import BaseModel
import firebase_admin
from firebase_admin import credentials, auth, firestore
from typing import Optional
from fastapi import APIRouter

userRouter = APIRouter()

# Initialize Firebase
cred = credentials.Certificate("path/to/your/firebase_credentials.json")
firebase_admin.initialize_app(cred)
db = firestore.client()

app = FastAPI()

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")

class User(BaseModel):
    username: str
    social_login_type: Optional[str] = None

class UserInDB(User):
    user_id: str

async def get_current_user(id_token: str = Depends(oauth2_scheme)):
    try:
        decoded_token = auth.verify_id_token(id_token)
        uid = decoded_token['uid']
        user_doc = db.collection('users').document(uid).get()
        if user_doc.exists:
            user_data = user_doc.to_dict()
            return UserInDB(**user_data, user_id=uid)
        else:
            raise HTTPException(status_code=404, detail="User not found")
    except Exception as e:
        raise HTTPException(status_code=401, detail="Invalid authentication credentials")

@userRouter.post("/register", response_model=UserInDB)
async def register(user: User, id_token: str = Header(None)):
    if not id_token:
        raise HTTPException(status_code=400, detail="ID token is required")
    
    try:
        # Verify the ID token
        decoded_token = auth.verify_id_token(id_token)
        uid = decoded_token['uid']
        
        # Check if user already exists
        user_doc = db.collection('users').document(uid).get()
        if user_doc.exists:
            raise HTTPException(status_code=400, detail="User already registered")
        
        # Create user document in Firestore
        user_data = {
            "username": user.username,
            "social_login_type": user.social_login_type or decoded_token.get('firebase', {}).get('sign_in_provider')
        }
        db.collection('users').document(uid).set(user_data)
        
        return UserInDB(**user_data, user_id=uid)
    except auth.InvalidIdTokenError:
        raise HTTPException(status_code=401, detail="Invalid ID token")
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@userRouter.post("/login", response_model=UserInDB)
async def login(id_token: str = Header(None)):
    if not id_token:
        raise HTTPException(status_code=400, detail="ID token is required")
    
    try:
        # Verify the ID token
        decoded_token = auth.verify_id_token(id_token)
        uid = decoded_token['uid']
        
        # Get user data from Firestore
        user_doc = db.collection('users').document(uid).get()
        if not user_doc.exists:
            raise HTTPException(status_code=404, detail="User not found")
        
        user_data = user_doc.to_dict()
        return UserInDB(**user_data, user_id=uid)
    except auth.InvalidIdTokenError:
        raise HTTPException(status_code=401, detail="Invalid ID token")
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@userRouter.get("/users/me", response_model=UserInDB)
async def read_users_me(current_user: UserInDB = Depends(get_current_user)):
    return current_user

@userRouter.put("/users/me", response_model=UserInDB)
async def update_user(user: User, current_user: UserInDB = Depends(get_current_user)):
    user_ref = db.collection('users').document(current_user.user_id)
    update_data = user.dict(exclude_unset=True)
    user_ref.update(update_data)
    updated_user = user_ref.get().to_dict()
    return UserInDB(**updated_user, user_id=current_user.user_id)

@userRouter.delete("/users/me", status_code=204)
async def delete_user(current_user: UserInDB = Depends(get_current_user)):
    try:
        auth.delete_user(current_user.user_id)
        db.collection('users').document(current_user.user_id).delete()
    except auth.UserNotFoundError:
        raise HTTPException(status_code=404, detail="User not found")
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)