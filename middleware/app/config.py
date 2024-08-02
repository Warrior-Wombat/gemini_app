import os
import firebase_admin
from firebase_admin import credentials, firestore
import google.generativeai as genai
from google.generativeai.types import HarmCategory, HarmBlockThreshold
import dotenv
from openai import OpenAI
dotenv.load_dotenv()

cred = credentials.Certificate("../credentials/firebase_credentials.json")
firebase_admin.initialize_app(cred)
db = firestore.client()

genai.configure(api_key=os.getenv('GEMINI_API_KEY'))
openai_client = OpenAI(api_key=os.getenv('OPENAI_API_KEY'))
