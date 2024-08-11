import google.generativeai as genai
import logging
from typing import List, Tuple, Dict
from google.api_core import exceptions as google_exceptions
from io import BytesIO
import io
import subprocess
from ..services.config import model, SAFETY_SETTINGS

class GeminiPredictor:
    def __init__(self):
        self.conversation_history = []
        self.context_cache = {}
        self.cache_size = 1000
        self.initial_prompt_sent = False
        self.word_frequency: Dict[str, Dict[str, int]] = {}
        self.chat_model = genai.GenerativeModel('gemini-1.5-flash')
        self.chat = self.chat_model.start_chat(history=[])

    def get_predictions(self, context: List[str], user_id: str, is_new_sentence: bool, k: int = 9) -> Tuple[List[str], List[str]]:
        if not self.initial_prompt_sent:
            full_context = ' '.join(self.conversation_history + context)
            user_prompt = f"""You are an advanced AI model designed to predict the user's next word with high accuracy. Your task is to predict the user's next word, listing 9 possible choices they might choose given the conversation at hand. NEVER SUGGEST OR LIST ANY PUNCTUATION MARKS THAT END A SENTENCE WHATSOEVER. Contraction words are fine. The user (User) is the one you are predicting the next word for. The other participant (Taker) responds to the user's words. It is important to predict the user's next word based on their intent and in response to what the Taker might say.
            
            This is the user's first word. Please give 9 more words that, individually, they can add after their first word. Note that for every single 9-word batch prediction you make, the 9 words are intended to be separate predictions for the conversation at hand, and each prediction is meant to serve as the next word in the User's sentence.

            {full_context}

            Suggest 9 words that would be most relevant and helpful for the user (User) to communicate next. Note that these are all supposed to be sentence starter, capital words. Consider the conversation flow, topic, and user's communication style. Respond with only the suggestions, separated by commas, without any additional text."""
            
            self.initial_prompt_sent = True
        else:
            current_context = ' '.join(context[-10:])
            user_prompt = f"""The user (User) and the receiver (Taker) are having a conversation. The user starts speaking first. You can safely assume that any lines that are not labeled with (Taker) are what the user has said. If the line ends on a Taker line, please recommend 9 predictions as per usual for the first word the user could say in response to what the Taker has said, taking into account the entire conversation as a whole.
            
            Given the current context:

            {current_context}

            Suggest 9 words that would be most relevant and helpful for the user (User) to communicate next. Please note that these words are not all meant to piece together a sentence - each of these 9 words are contesting to fill up the same word slot, sort of like a phone's ngram autocomplete. NEVER SUGGEST OR LIST ANY PUNCTUATION MARKS THAT END A SENTENCE WHATSOEVER. Apostrophes/contractions are fine.
            Consider the conversation flow, topic, and user's communication style.
            Respond with only the suggestions, separated by commas, without any additional text."""
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

    def get_taker_response(self, transcription: str) -> List[str]:
        context = self.conversation_history + [f"(Taker): {transcription}"]
        user_prompt = f"""The user (User) and the receiver (Taker) are having a conversation. The user starts speaking first. You can safely assume that any lines that are not labeled with (Taker) are what the user has said. If the line ends on a Taker line, please recommend 9 predictions as per usual for the first word the user could say in response to what the Taker has said, taking into account the entire conversation as a whole.
        
        Given the current context:

        {' '.join(context)}

        Suggest 9 words that would be most relevant and helpful for the user (User) to communicate next.
        Consider the conversation flow, topic, and user's communication style.
        Respond with only the suggestions, separated by commas, without any additional text."""
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

    def get_image_predictions(self, image_data: BytesIO, k: int = 9) -> List[str]:
        image_data.seek(0)
        image_bytes = image_data.read()

        user_prompt = f"""You are an advanced AI model designed to provide descriptive words for images with high accuracy. Your task is to describe the contents of the image by listing {k} words that best represent the objects, scenes, or concepts depicted in the image. Ensure that the words are relevant, concise, and varied.

        Provide {k} descriptive words for the given image. Respond with only the words, separated by commas, without any additional text."""

        logging.info(f"Prompt being passed to Gemini API for image prediction:\nUser Prompt: {user_prompt}")

        try:

            content = [
                user_prompt,
                {"mime_type": "image/jpeg", "data": image_bytes}
            ]

            response = self.chat_model.generate_content(content, safety_settings=SAFETY_SETTINGS)
            if response.candidates and response.candidates[0].content.parts:
                text = response.candidates[0].content.parts[0].text
                predictions = [word.strip() for word in text.split(',') if word.strip()]
                logging.info(f"Predictions received: {predictions}")
                return predictions[:k]
            else:
                logging.error("Gemini API returned no content for image prediction.")
                return self.get_default_predictions(k, is_new_sentence=False)
        except google_exceptions.GoogleAPIError as e:
            logging.error(f"Error calling Gemini API for image prediction: {str(e)}")
            return self.get_default_predictions(k, is_new_sentence=False)
        except Exception as e:
            logging.error(f"Unexpected error in get_image_predictions: {str(e)}")
            return self.get_default_predictions(k, is_new_sentence=False)
        
    def get_search_predictions(self, input_string: str, k: int = 20) -> List[str]:
        user_prompt = f"""You are an advanced AI model designed to complete user input with high accuracy. Given a partial input string, your task is to predict and list {k} possible completions where each completion is a singular word. Your suggestions should be relevant and diverse, considering various possible completions based on the given input string. For example, if the user types 'i', you should list words that start with 'i' ONLY. If the user types 'im', you should reply with words that start with 'im' ONLY. Singular words, not multiple. 

        Here is the input string:
        "{input_string}"

        Provide {k} completions for the given input string. Respond with only the words, separated by commas, without any additional text."""

        logging.info(f"Prompt being passed to Gemini API for autocomplete predictions:\nUser Prompt: {user_prompt}")

        try:
            response = self.chat.send_message(user_prompt, safety_settings=SAFETY_SETTINGS)
            text = response.text
            
            if not text:
                logging.warning("Gemini API returned an empty response for autocomplete predictions")
                return self.get_default_predictions(k, is_new_sentence=False)
            suggestions = [suggestion.strip() for suggestion in text.split(',') if suggestion.strip() and not any(punct in suggestion for punct in ['.', '!', '?'])]
            suggestions = suggestions[:k]
            
            return suggestions

        except google_exceptions.GoogleAPIError as e:
            logging.error(f"Error calling Gemini API for autocomplete predictions: {str(e)}")
            return self.get_default_predictions(k, is_new_sentence=False)
        except Exception as e:
            logging.error(f"Unexpected error in get_autocomplete_predictions: {str(e)}")
            return self.get_default_predictions(k, is_new_sentence=False)