import logging
from typing import List, Tuple, Dict
import pyaudio
import wave
from io import BytesIO
from threading import Thread, Event
from ..services.config import db
from ..classes.gemini_predictor import GeminiPredictor

class UserSession:
    sessions: Dict[str, 'UserSession'] = {}

    def __init__(self, user_id: str):
        self.user_id = user_id
        self.predictor = GeminiPredictor()
        self.current_sentence = []
        self.is_new_sentence = True
        self.recording_thread = None
        self.stop_recording_event = Event()
        self.audio_buffer = BytesIO()
        self.load_user_data()

    def load_user_data(self):
        user_doc = db.collection('users').document(self.user_id).collection('embeddings').document('data').get()
        if user_doc.exists:
            data = user_doc.to_dict()
            self.predictor.word_frequency = data.get('word_frequency', {})

    def save_user_data(self):
        db.collection('users').document(self.user_id).collection('embeddings').document('data').set({
            'word_frequency': self.predictor.word_frequency,
        }, merge=True)

    def get_predictions(self, current_input: str) -> Tuple[List[str], List[str]]:
        context = self.current_sentence + [current_input]
        gemini_predictions, _ = self.predictor.get_predictions(context, self.user_id, self.is_new_sentence)
        usage_based_predictions = self.predictor.get_usage_based_predictions(context[-1] if context else '', k=6)
        logging.info(f"Usage-based predictions: {usage_based_predictions}")
        return gemini_predictions, usage_based_predictions

    def update_model(self, selected_word: str):
        self.predictor.update_history(selected_word)
        self.current_sentence.append(selected_word)

        if len(self.current_sentence) > 1:
            last_word = self.current_sentence[-2]
            self.update_word_frequency(last_word, selected_word)
        
        if selected_word.endswith('.'):
            self.end_sentence()
        else:
            self.is_new_sentence = False

    def end_sentence(self):
        self.current_sentence = []
        self.is_new_sentence = True
        self.save_user_data()

    def label_response(self, transcription: str):
        if transcription:
            logging.debug(f"Transcribed: {transcription}")
            taker_response = f"(Taker): {transcription}"
            self.predictor.conversation_history.append(taker_response)
            logging.debug(f"Updated conversation history with Taker response: {self.predictor.conversation_history}")
            predictions = self.predictor.get_taker_response(transcription)
            logging.debug(f"Suggested words/phrases for user response: {', '.join(predictions)}")
            return {
                "taker_response": taker_response,
                "predictions": predictions
            }

    def update_word_frequency(self, last_word: str, selected_word: str):
        if not last_word:
            last_word = '<START>'
        if not selected_word:
            selected_word = '<END>'
        
        if last_word not in self.predictor.word_frequency:
            self.predictor.word_frequency[last_word] = {}

        if selected_word not in self.predictor.word_frequency[last_word]:
            self.predictor.word_frequency[last_word][selected_word] = 0

        self.predictor.word_frequency[last_word][selected_word] += 1
        logging.debug(f"Updated word frequency: {self.predictor.word_frequency}")
    
    @classmethod
    def get_user_session(cls, user_id: str) -> 'UserSession':
        if user_id not in cls.sessions:
            cls.sessions[user_id] = cls(user_id)
        return cls.sessions[user_id]
