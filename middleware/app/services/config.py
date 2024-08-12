import os
import firebase_admin
from firebase_admin import credentials, firestore
import google.generativeai as genai
from google.generativeai.types import HarmCategory, HarmBlockThreshold
from dotenv import load_dotenv
from openai import OpenAI

load_dotenv()

cred = credentials.Certificate("credentials/firebase_credentials.json")
firebase_admin.initialize_app(cred)
db = firestore.client()

gemini_api_key = os.environ.get('GEMINI_API_KEY')
if not gemini_api_key:
    raise ValueError("GEMINI_API_KEY environment variable is not set")

genai.configure(api_key=gemini_api_key)
model = genai.GenerativeModel(model_name='gemini-1.5-flash')

# disabling safety settings because it doesn't make sense to reject transcriptions for something that someone else said.
SAFETY_SETTINGS = {
    HarmCategory.HARM_CATEGORY_HATE_SPEECH: HarmBlockThreshold.BLOCK_LOW_AND_ABOVE,
    HarmCategory.HARM_CATEGORY_HARASSMENT: HarmBlockThreshold.BLOCK_LOW_AND_ABOVE,
}
