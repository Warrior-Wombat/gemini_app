import logging
from typing import List, Tuple
from firebase_admin import firestore
from app.services.gemini_predictor import GeminiPredictor
from io import BytesIO
import pyaudio
import wave

db = firestore.client()

class User:
    def __init__(self, user_id: str):
        self.user_id = user_id
        self.predictor = GeminiPredictor()
        self.current_sentence = []
        self.is_new_sentence = True
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
        self.listen_for_context()

    def listen_for_context(self):
        print("\nListening for conversation context. Speak now...")
        audio_data = self.record_audio()
        if audio_data:
            transcription = self.predictor.transcribe_audio(audio_data)
            if transcription:
                print(f"Transcribed: {transcription}")
                taker_response = f"(Taker): {transcription}"
                self.predictor.conversation_history.append(taker_response)
                logging.debug(f"Updated conversation history with Taker response: {self.predictor.conversation_history}")
                predictions = self.predictor.get_taker_response(transcription)
                print("Suggested words/phrases for user response:", ', '.join(predictions))

    def record_audio(self, duration=5, sample_rate=16000, channels=1, chunk=1024):
        p = pyaudio.PyAudio()
        stream = p.open(format=pyaudio.paInt16,
                        channels=channels,
                        rate=sample_rate,
                        input=True,
                        frames_per_buffer=chunk)

        print("Recording...")
        frames = []
        for _ in range(0, int(sample_rate / chunk * duration)):
            data = stream.read(chunk)
            frames.append(data)
        print("Recording finished.")

        stream.stop_stream()
        stream.close()
        p.terminate()

        audio_data = BytesIO()
        wf = wave.open(audio_data, 'wb')
        wf.setnchannels(channels)
        wf.setsampwidth(p.get_sample_size(pyaudio.paInt16))
        wf.setframerate(sample_rate)
        wf.writeframes(b''.join(frames))
        wf.close()

        audio_data.seek(0)
        return audio_data

    def handle_image_input(self, image_path: str) -> str:
        summary = self.predictor.generate_image_summary(image_path)
        self.update_model(summary)
        predictions, _ = self.get_predictions("")
        return summary, predictions

    def update_word_frequency(self, last_word: str, selected_word: str):
        if last_word not in self.predictor.word_frequency:
            self.predictor.word_frequency[last_word] = {}

        if selected_word not in self.predictor.word_frequency[last_word]:
            self.predictor.word_frequency[last_word][selected_word] = 0

        self.predictor.word_frequency[last_word][selected_word] += 1
        logging.debug(f"Updated word frequency: {self.predictor.word_frequency}")
