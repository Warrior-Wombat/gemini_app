import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

import '../models/prediction.dart';

class PredictionService {
  final String baseUrl = 'http://192.168.0.197:5000/autocomplete';
  final Logger _logger = Logger();

  Future<Map<String, List<Prediction>>> getPredictions(String userId, String lastWord) async {
    final response = await http.post(
      Uri.parse('$baseUrl/user_input'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'user_id': userId,
        'input_text': lastWord,
      }),
    );

    _logger.i('Request to /user_input: $baseUrl/user_input, body: ${json.encode({
      'user_id': userId,
      'input_text': lastWord,
    })}');

    if (response.statusCode == 200) {
      Map<String, dynamic> body = json.decode(response.body);

      _logger.i('Response from /user_input: ${response.body}');

      List<Prediction> geminiPredictions = [
        ...(body['gemini_predictions'] as List).map((word) => Prediction(word: word.toString())).toList(),
      ];

      List<Prediction> usageBasedPredictions = [
        ...(body['usage_based_predictions'] as List).map((word) => Prediction(word: word.toString())).toList(),
      ];

      return {
        'gemini_predictions': geminiPredictions,
        'usage_based_predictions': usageBasedPredictions,
      };
    } else {
      _logger.e('Failed to load predictions: ${response.statusCode}, ${response.body}');
      throw Exception('Failed to load predictions');
    }
  }

  Future<void> updateModel(String userId, String selectedWord) async {
    final response = await http.post(
      Uri.parse('$baseUrl/user_input'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'user_id': userId,
        'input_text': selectedWord,
      }),
    );

    _logger.i('Request to /user_input for update: $baseUrl/user_input, body: ${json.encode({
      'user_id': userId,
      'input_text': selectedWord,
    })}');

    if (response.statusCode != 200) {
      _logger.e('Failed to update model: ${response.statusCode}, ${response.body}');
      throw Exception('Failed to update model');
    }
  }

  Future<void> handleImageInput(String userId, String imagePath) async {
    final response = await http.post(
      Uri.parse('$baseUrl/image_input'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'user_id': userId,
        'image_path': imagePath,
      }),
    );

    _logger.i('Request to /image_input: $baseUrl/image_input, body: ${json.encode({
      'user_id': userId,
      'image_path': imagePath,
    })}');

    if (response.statusCode != 200) {
      _logger.e('Failed to handle image input: ${response.statusCode}, ${response.body}');
      throw Exception('Failed to handle image input');
    }
  }

  Future<void> endSession(String userId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/end_session'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'user_id': userId,
      }),
    );

    _logger.i('Request to /end_session: $baseUrl/end_session, body: ${json.encode({
      'user_id': userId,
    })}');

    if (response.statusCode != 200) {
      _logger.e('Failed to end session: ${response.statusCode}, ${response.body}');
      throw Exception('Failed to end session');
    }
  }

  Future<void> listenAudio(String userId, File audioFile) async {
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/listen_audio'))
      ..fields['user_id'] = userId
      ..files.add(await http.MultipartFile.fromPath('file', audioFile.path));

    _logger.i('Request to /listen_audio: $baseUrl/listen_audio, file: ${audioFile.path}');

    final response = await request.send();

    if (response.statusCode == 200) {
      final responseBody = await response.stream.bytesToString();
      _logger.i('Response from /listen_audio: $responseBody');
    } else {
      final responseBody = await response.stream.bytesToString();
      _logger.e('Failed to process audio: ${response.statusCode}, $responseBody');
      throw Exception('Failed to process audio');
    }
  }
}
