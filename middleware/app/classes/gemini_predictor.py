import google.generativeai as genai
import logging
from typing import List, Tuple, Dict
from google.api_core import exceptions as google_exceptions
from io import BytesIO
import io
import subprocess
from ..services.config import model, SAFETY_SETTINGS, openai_client


class GeminiPredictor:
    def __init__(self):
        self.conversation_history = []
        self.context_cache = {}
        self.cache_size = 1000
        self.initial_prompt_sent = False
        self.word_frequency: Dict[str, Dict[str, int]] = {}
        # Initialize chat session
        self.chat_model = genai.GenerativeModel('gemini-1.5-flash')
        self.chat = self.chat_model.start_chat(history=[])

    def get_predictions(self, context: List[str], user_id: str, is_new_sentence: bool, k: int = 9) -> Tuple[List[str], List[str]]:
        if not self.initial_prompt_sent:
            full_context = ' '.join(self.conversation_history + context)
            user_prompt = f"""You are an advanced AI model designed to predict the user's next word with high accuracy. Your task is to predict the user's next word, listing 9 possible choices they might choose given the conversation at hand. NEVER SUGGEST OR LIST ANY PUNCTUATION MARKS WHATSOEVER. The user (User) is the one you are predicting the next word for. The other participant (Taker) responds to the user's words. It is important to predict the user's next word based on their intent and in response to what the Taker might say.
            
            This is the user's first word. Please give 9 more words that, individually, they can add after their first word. Note that for every single 9-word batch prediction you make, the 9 words are intended to be separate predictions for the conversation at hand, and each prediction is meant to serve as the next word in the User's sentence.

            {full_context}

            Suggest 9 words that would be most relevant and helpful for the user (User) to communicate next. Note that these are all supposed to be sentence starter, capital words. Consider the conversation flow, topic, and user's communication style. Respond with only the suggestions, separated by commas, without any additional text."""
            
            self.initial_prompt_sent = True
        else:
            current_context = ' '.join(context[-10:])
            user_prompt = f"""The user (User) and the receiver (Taker) are having a conversation. The user starts speaking first. You can safely assume that any lines that are not labeled with (Taker) are what the user has said. If the line ends on a Taker line, please recommend 9 predictions as per usual for the first word the user could say in response to what the Taker has said, taking into account the entire conversation as a whole.
            
            Given the current context:

            {current_context}

            Suggest 9 words that would be most relevant and helpful for the user (User) to communicate next. Please note that these words are not all meant to piece together a sentence - each of these 9 words are contesting to fill up the same word slot, sort of like a phone's ngram autocomplete. NEVER SUGGEST OR LIST ANY PUNCTUATION MARKS WHATSOEVER.
            Consider the conversation flow, topic, and user's communication style.
            Respond with only the suggestions, separated by commas, without any additional text."""

        # Log the prompt being passed to the Gemini API
        logging.info(f"Prompt being passed to Gemini API:\nUser Prompt: {user_prompt}")

        try:
            response = self.chat.send_message(user_prompt, safety_settings=SAFETY_SETTINGS)
            suggestions = self.process_response(response, k, is_new_sentence)
            adjusted_suggestions = self.adjust_predictions_based_on_usage(context[-1] if context else '', suggestions)
            return adjusted_suggestions, []
        except google_exceptions.GoogleAPIError as e:
            logging.error(f"Error calling Gemini API: {str(e)}")
            return self.get_default_predictions(k, is_new_sentence), []
        except Exception as e:
            logging.error(f"Unexpected error in get_predictions: {str(e)}")
            return self.get_default_predictions(k, is_new_sentence), []

    def process_response(self, response, k: int, is_new_sentence: bool) -> List[str]:
        if not response.text:
            logging.warning("Gemini API returned an empty response")
            return self.get_default_predictions(k, is_new_sentence)

        text = response.text
        suggestions = [suggestion.strip() for suggestion in text.split(',') if suggestion.strip()]

        if not suggestions:
            logging.warning("No valid suggestions extracted from Gemini API response")
            return self.get_default_predictions(k, is_new_sentence)

        suggestions = suggestions[:k]
        while len(suggestions) < k:
            suggestions.append(self.get_default_predictions(1, is_new_sentence)[0])

        if is_new_sentence and suggestions:
            suggestions[0] = suggestions[0].capitalize()

        return suggestions

    def get_default_predictions(self, k: int, is_new_sentence: bool) -> List[str]:
        default_words = ["the", "is", "a", "to", "of", "and", "in", "that", "for"]
        if is_new_sentence:
            default_words = [word.capitalize() for word in default_words]
        return default_words[:k]

    def adjust_predictions_based_on_usage(self, last_word: str, suggestions: List[str]) -> List[str]:
        if last_word not in self.word_frequency:
            return suggestions

        word_freq = self.word_frequency[last_word]
        sorted_suggestions = sorted(suggestions, key=lambda x: word_freq.get(x, 0), reverse=True)
        return sorted_suggestions

    def get_usage_based_predictions(self, last_word: str, k: int = 6) -> List[str]:
        if last_word in self.word_frequency:
            sorted_predictions = sorted(self.word_frequency[last_word].items(), key=lambda item: item[1], reverse=True)
            return [word for word, freq in sorted_predictions[:k]]
        return []

    def update_history(self, selected_word: str):
        self.conversation_history.append(selected_word)
        logging.debug(f"Updated conversation history: {self.conversation_history}")

    def convert_to_wav(self, audio_buffer: BytesIO) -> BytesIO:
        audio_buffer.seek(0)

        process = subprocess.Popen(
            ['ffmpeg', '-i', '-', '-ac', '1', '-ar', '16000', '-f', 'wav', '-'],
            stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE
        )

        wav_data, error = process.communicate(input=audio_buffer.read())

        if process.returncode != 0:
            raise ValueError(f"FFmpeg error: {error.decode()}")

        return io.BytesIO(wav_data)

    def transcribe_audio(self, audio_data: BytesIO) -> str:
        try:
            wav_buffer = self.convert_to_wav(audio_data)
            wav_buffer.name = 'audio.wav'

            logging.info("Transcription request being sent to OpenAI API")
            response = openai_client.audio.transcriptions.create(
                model="whisper-1",
                file=wav_buffer
            )
            transcription = response.text
            logging.info(f"Transcribed audio: {transcription}")
            return transcription
        except Exception as e:
            logging.error(f"Error transcribing audio: {str(e)}")
            return ""

    def get_taker_response(self, transcription: str) -> List[str]:
        context = self.conversation_history + [f"(Taker): {transcription}"]
        user_prompt = f"""The user (User) and the receiver (Taker) are having a conversation. The user starts speaking first. You can safely assume that any lines that are not labeled with (Taker) are what the user has said. If the line ends on a Taker line, please recommend 9 predictions as per usual for the first word the user could say in response to what the Taker has said, taking into account the entire conversation as a whole.
        
        Given the current context:

        {' '.join(context)}

        Suggest 9 words that would be most relevant and helpful for the user (User) to communicate next.
        Consider the conversation flow, topic, and user's communication style.
        Respond with only the suggestions, separated by commas, without any additional text."""

        # Log the prompt being passed to the Gemini API for the taker response
        logging.info(f"Prompt being passed to Gemini API for taker response:\nUser Prompt: {user_prompt}")

        try:
            response = self.chat.send_message(user_prompt, safety_settings=SAFETY_SETTINGS)
            suggestions = self.process_response(response, k=9, is_new_sentence=True)
            return suggestions
        except google_exceptions.GoogleAPIError as e:
            logging.error(f"Error calling Gemini API for taker response: {str(e)}")
            return self.get_default_predictions(k=9, is_new_sentence=True)
        except Exception as e:
            logging.error(f"Unexpected error in get_taker_response: {str(e)}")
            return self.get_default_predictions(k=9, is_new_sentence=True)

    def generate_image_summary(self, image_path: str) -> str:
        try:
            with open(image_path, 'rb') as image_file:
                image_data = image_file.read()

            # Prepare the image data in the correct format
            image_part = {"mime_type": "image/jpeg", "data": image_data}
            prompt_parts = [
                {"mime_type": "text/plain", "data": "Provide a one-word summary for the object in the following image:"},
                image_part
            ]

            # Log the prompt being passed to the Gemini API for image summary
            logging.info("Image summary prompt being passed to Gemini API.")

            response = model.generate_content(prompt_parts, safety_settings=SAFETY_SETTINGS)
            if response.candidates and response.candidates[0].content:
                summary = response.candidates[0].content.strip()
                logging.info(f"Image summary: {summary}")
                return summary
            else:
                logging.error(f"Image summary failed: {response}")
                return "unknown"
        except Exception as e:
            logging.error(f"Error generating image summary: {str(e)}")
            return "unknown"