import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

class SearchService extends ChangeNotifier {
  final String baseUrl = 'http://192.168.0.197:5000/autocomplete';
  final Logger _logger = Logger();
  List<String> _searchResults = [];

  List<String> get searchResults => _searchResults;

  Future<List<String>> getSearchPredictions(String userId, String query) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/search'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': userId,
          'query': query,
        }),
      );

      _logger.i('Request to /search: $baseUrl, body: ${json.encode({'user_id': userId, 'query': query})}');

      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        final List<String> predictions = List<String>.from(responseBody['predictions']);
        _searchResults = predictions;
        notifyListeners();
        return predictions;
      } else {
        _logger.e('Failed to get search predictions: ${response.statusCode}, ${response.body}');
        throw Exception('Failed to get search predictions');
      }
    } catch (e) {
      _logger.e('Error getting search predictions: $e');
      throw Exception('Error getting search predictions: $e');
    }
  }
}
