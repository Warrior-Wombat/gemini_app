import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../models/prediction.dart';
import '../services/prediction_service.dart';

class PredictionScreen extends StatefulWidget {
  @override
  _PredictionScreenState createState() => _PredictionScreenState();
}

class _PredictionScreenState extends State<PredictionScreen> with WidgetsBindingObserver {
  final List<String> collectedWords = [];
  List<String> defaultWords = ["Hello", "Hi", "Hey", "Good", "How", "What", "When", "Where", "Why"];
  late Future<Map<String, List<Prediction>>> predictions;
  String userId = '';
  String lastWord = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    userId = FirebaseAuth.instance.currentUser?.uid ?? 'unauthenticated';
    predictions = Provider.of<PredictionService>(context, listen: false).getPredictions(userId, lastWord);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _callEndSession();
    }
    super.didChangeAppLifecycleState(state);
  }

  // resets conversation history when app is closed
  void _callEndSession() async {
    final response = await http.post(
      Uri.parse('http://192.168.0.197:8000/autocomplete/end_session'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'user_id': userId}),
    );
    if (response.statusCode != 200) {
      print('Failed to end session: ${response.body}');
    }
  }

  void updatePredictions(String selectedWord) {
    setState(() {
      collectedWords.add(selectedWord);
      lastWord = selectedWord;
      predictions = Provider.of<PredictionService>(context, listen: false).getPredictions(userId, lastWord);
    });
  }

  void submitPeriod() {
    setState(() {
      collectedWords.add('.');
      lastWord = '.';
      predictions = Provider.of<PredictionService>(context, listen: false).getPredictions(userId, lastWord);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Predictions'),
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16.0),
            color: Colors.grey[200],
            child: Text(
              collectedWords.join(' '),
              style: TextStyle(fontSize: 24),
            ),
          ),
          Expanded(
            child: FutureBuilder<Map<String, List<Prediction>>>(
              future: predictions,
              builder: (context, snapshot) {
                if (collectedWords.isEmpty) {
                  // Display default words initially
                  return GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 2,
                    ),
                    itemCount: defaultWords.length + 1, // Add one for the period tile
                    itemBuilder: (context, index) {
                      if (index == defaultWords.length) {
                        // Period tile
                        return GestureDetector(
                          onTap: submitPeriod,
                          child: Card(
                            color: Colors.redAccent,
                            child: Center(
                              child: Text(
                                '.',
                                style: TextStyle(color: Colors.white, fontSize: 24),
                              ),
                            ),
                          ),
                        );
                      } else {
                        final word = defaultWords[index];
                        return GestureDetector(
                          onTap: () => updatePredictions(word),
                          child: Card(
                            color: Colors.blueAccent,
                            child: Center(
                              child: Text(
                                word,
                                style: TextStyle(color: Colors.white, fontSize: 18),
                              ),
                            ),
                          ),
                        );
                      }
                    },
                  );
                } else if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No predictions available'));
                }

                // Combine the predictions into a single list for display
                final predictions = [
                  ...snapshot.data!['gemini_predictions']!,
                  ...snapshot.data!['usage_based_predictions']!,
                ];

                return GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 2,
                  ),
                  itemCount: predictions.length + 1, // Add one for the period tile
                  itemBuilder: (context, index) {
                    if (index == predictions.length) {
                      // Period tile
                      return GestureDetector(
                        onTap: submitPeriod,
                        child: Card(
                          color: Colors.redAccent,
                          child: Center(
                            child: Text(
                              '.',
                              style: TextStyle(color: Colors.white, fontSize: 24),
                            ),
                          ),
                        ),
                      );
                    } else {
                      final prediction = predictions[index];
                      return GestureDetector(
                        onTap: () => updatePredictions(prediction.word),
                        child: Card(
                          color: Colors.blueAccent,
                          child: Center(
                            child: Text(
                              prediction.word,
                              style: TextStyle(color: Colors.white, fontSize: 18),
                            ),
                          ),
                        ),
                      );
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
