import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/prediction.dart';

class PredictionService {
  final String baseUrl = 'http://192.168.0.197:5000/autocomplete';

  Future<List<Prediction>> getPredictions(String userId, String lastWord) async {
    final response = await http.get(
      Uri.parse('$baseUrl/autocomplete?user_id=$userId&last_word=$lastWord'),
    );

    if (response.statusCode == 200) {
      List<dynamic> body = json.decode(response.body);
      List<Prediction> predictions = body.map((word) => Prediction(word: word.toString())).toList();
      return predictions;
    } else {
      throw Exception('Failed to load predictions');
    }
  }
}