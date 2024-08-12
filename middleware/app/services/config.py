import os
import firebase_admin
from firebase_admin import credentials, firestore
from google.auth import default
from google.auth.transport.requests import Request
import google.generativeai as genai
from google.generativeai.types import HarmCategory, HarmBlockThreshold
from dotenv import load_dotenv

load_dotenv()

cred = credentials.Certificate("credentials/firebase_credentials.json")
firebase_admin.initialize_app(cred)
db = firestore.client()

# gcp credentials?
credentials, _ = default()
if hasattr(credentials, 'refresh'):
    credentials.refresh(Request())

genai.configure(credentials=credentials)
model = genai.GenerativeModel(model_name='gemini-1.5-flash')

# disabling safety settings because it doesn't make sense to reject transcriptions for something that someone else said.
SAFETY_SETTINGS = {
    HarmCategory.HARM_CATEGORY_HATE_SPEECH: HarmBlockThreshold.BLOCK_LOW_AND_ABOVE,
    HarmCategory.HARM_CATEGORY_HARASSMENT: HarmBlockThreshold.BLOCK_LOW_AND_ABOVE,
}
