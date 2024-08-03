import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/prediction.dart';
import '../services/prediction_service.dart';

class PredictionScreen extends StatefulWidget {
  @override
  _PredictionScreenState createState() => _PredictionScreenState();
}

class _PredictionScreenState extends State<PredictionScreen> {
  final List<String> collectedWords = [];
  List<String> defaultWords = ["Hello", "Hi", "Hey", "Good", "How", "What", "When", "Where", "Why"];
  late Future<List<Prediction>> predictions;
  String userId = 'test_user'; // Replace with actual user ID
  String lastWord = '';

  @override
  void initState() {
    super.initState();
    predictions = Provider.of<PredictionService>(context, listen: false).getPredictions(userId, lastWord);
  }

  void updatePredictions(String selectedWord) {
    setState(() {
      collectedWords.add(selectedWord);
      lastWord = selectedWord;
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
            child: FutureBuilder<List<Prediction>>(
              future: predictions,
              builder: (context, snapshot) {
                if (collectedWords.isEmpty) {
                  // Display default words initially
                  return GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 2,
                    ),
                    itemCount: defaultWords.length,
                    itemBuilder: (context, index) {
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
                    },
                  );
                } else if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No predictions available'));
                }

                return GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 2,
                  ),
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final prediction = snapshot.data![index];
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
