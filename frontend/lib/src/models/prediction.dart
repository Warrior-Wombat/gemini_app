class Prediction {
  final String word;

  Prediction({required this.word});

  factory Prediction.fromJson(Map<String, dynamic> json) {
    return Prediction(word: json['word']);
  }
}