class Prediction {
  final String word;
  bool disabled;

  Prediction({required this.word, this.disabled = false});

  factory Prediction.fromJson(Map<String, dynamic> json) {
    return Prediction(word: json['word'], disabled: false);
  }
}
