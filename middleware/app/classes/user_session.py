from typing import List
from app import db
from ..classes.weighted_ngram import WeightedNGramModel
from ..classes.hybrid_predictor import HybridPredictor

class UserSession:
    def __init__(self, user_id: str):
        self.user_id = user_id
        self.ngram_model = WeightedNGramModel()
        self.predictor = HybridPredictor(self.ngram_model)
        self.conversation_history = []
        self.load_user_data()

    def load_user_data(self):
        # Load user data from Firebase
        user_doc = db.collection('users').document(self.user_id).get()
        if user_doc.exists:
            data = user_doc.to_dict()
            # Reconstruct n-gram model and predictor state
            # This is a simplified version and would need to be expanded
            self.ngram_model.ngrams = data.get('ngrams', {})
            self.ngram_model.total_counts = data.get('total_counts', {})
            self.predictor.ngram_weight = data.get('ngram_weight', 0.3)
            self.predictor.gemini_weight = 1 - self.predictor.ngram_weight

    def save_user_data(self):
        # Save user data to Firebase
        db.collection('users').document(self.user_id).set({
            'ngrams': self.ngram_model.ngrams,
            'total_counts': self.ngram_model.total_counts,
            'ngram_weight': self.predictor.ngram_weight,
            # Add other relevant data
        }, merge=True)

    def get_predictions(self, current_input: str) -> List[str]:
        context = ' '.join(self.conversation_history + [current_input])
        return self.predictor.get_predictions(context)

    def update_model(self, selected_word: str):
        self.conversation_history.append(selected_word)
        context = ' '.join(self.conversation_history)
        
        # Update n-gram model
        self.ngram_model.update(context)
        
        # Update predictor weights
        ngram_preds = self.ngram_model.predict(tuple(context.split()[-self.ngram_model.n+1:]))
        gemini_preds = self.predictor.get_gemini_predictions(context, 9)
        self.predictor.update_weights(selected_word, ngram_preds, gemini_preds)
        
        # Check if accuracy threshold is met
        if self.predictor.check_accuracy() >= 0.98:
            print("Model has reached 98% accuracy!")
        
        # Periodically decay n-gram counts and save user data
        if len(self.conversation_history) % 100 == 0:
            self.ngram_model.decay_counts()
            self.save_user_data()