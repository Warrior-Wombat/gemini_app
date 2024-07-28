from typing import List, Tuple
from app import model
from ..classes.weighted_ngram import WeightedNGramModel

class HybridPredictor:
    def __init__(self, ngram_model: WeightedNGramModel, initial_ngram_weight: float = 0.3):
        self.ngram_model = ngram_model
        self.ngram_weight = initial_ngram_weight
        self.gemini_weight = 1 - initial_ngram_weight
        self.ngram_correct = 0
        self.gemini_correct = 0
        self.total_predictions = 0

    def get_predictions(self, context: str, k: int = 9) -> List[str]:
        # Get n-gram predictions
        context_tuple = tuple(context.split()[-self.ngram_model.n+1:])
        ngram_preds = self.ngram_model.predict(context_tuple, k)

        # Get Gemini API predictions
        gemini_preds = self.get_gemini_predictions(context, k)

        # Combine and rank predictions
        combined_preds = self.rank_predictions(ngram_preds, gemini_preds, k)

        return [word for word, _ in combined_preds]

    def get_gemini_predictions(self, context: str, k: int) -> List[Tuple[str, float]]:
        prompt = f"Given the context '{context}', predict the next {k} most likely words. Provide only the words, separated by commas."
        response = model.generate_content(prompt)
        words = [word.strip() for word in response.text.split(',')]
        # Assign decreasing probabilities to Gemini predictions
        return [(word, 1 - (i * 0.1)) for i, word in enumerate(words[:k])]

    def rank_predictions(self, ngram_preds: List[Tuple[str, float]], gemini_preds: List[Tuple[str, float]], k: int) -> List[Tuple[str, float]]:
        combined = {}
        for word, prob in ngram_preds:
            combined[word] = prob * self.ngram_weight
        for word, prob in gemini_preds:
            if word in combined:
                combined[word] += prob * self.gemini_weight
            else:
                combined[word] = prob * self.gemini_weight
        return sorted(combined.items(), key=lambda x: x[1], reverse=True)[:k]

    def update_weights(self, selected_word: str, ngram_preds: List[Tuple[str, float]], gemini_preds: List[Tuple[str, float]]):
        self.total_predictions += 1
        if selected_word in [word for word, _ in ngram_preds]:
            self.ngram_correct += 1
        if selected_word in [word for word, _ in gemini_preds]:
            self.gemini_correct += 1

        # Update weights based on accuracy
        if self.total_predictions > 0:
            self.ngram_weight = self.ngram_correct / self.total_predictions
            self.gemini_weight = self.gemini_correct / self.total_predictions

            # Normalize weights
            total_weight = self.ngram_weight + self.gemini_weight
            self.ngram_weight /= total_weight
            self.gemini_weight /= total_weight

    def check_accuracy(self) -> float:
        if self.total_predictions == 0:
            return 0
        return (self.ngram_correct + self.gemini_correct) / (2 * self.total_predictions)