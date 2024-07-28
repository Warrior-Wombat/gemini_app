import collections
from typing import List, Dict, Tuple

class WeightedNGramModel:
    def __init__(self, n: int = 3, decay_factor: float = 0.95):
        self.n = n
        self.ngrams: Dict[str, collections.Counter] = collections.defaultdict(collections.Counter)
        self.total_counts: Dict[str, int] = collections.defaultdict(int)
        self.decay_factor = decay_factor

    def update(self, text: str):
        words = text.split()
        for i in range(len(words) - self.n + 1):
            context = tuple(words[i:i+self.n-1])
            next_word = words[i+self.n-1]
            self.ngrams[context][next_word] += 1
            self.total_counts[context] += 1

    def predict(self, context: Tuple[str, ...], k: int = 9) -> List[Tuple[str, float]]:
        if context not in self.ngrams:
            return []
        
        total = self.total_counts[context]
        predictions = [(word, count / total) for word, count in self.ngrams[context].items()]
        return sorted(predictions, key=lambda x: x[1], reverse=True)[:k]

    def decay_counts(self):
        for context in self.ngrams:
            for word in self.ngrams[context]:
                self.ngrams[context][word] *= self.decay_factor
            self.total_counts[context] = sum(self.ngrams[context].values())
