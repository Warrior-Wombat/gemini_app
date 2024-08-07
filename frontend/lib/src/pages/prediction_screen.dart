import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/prediction_service.dart';

class PredictionScreen extends StatefulWidget {
  @override
  _PredictionScreenState createState() => _PredictionScreenState();
}

class _PredictionScreenState extends State<PredictionScreen> with WidgetsBindingObserver {
  final List<String> collectedWords = [];
  List<String> defaultWords = ["Hello", "Hi", "Hey", "Good", "How", "What", "When", "Where", "Why"];
  String userId = '';
  String lastWord = '';
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    userId = FirebaseAuth.instance.currentUser?.uid ?? 'unauthenticated';
    context.read<PredictionService>().getPredictions(userId, lastWord);
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

  void _callEndSession() async {
    await context.read<PredictionService>().endSession(userId);
  }

  void updatePredictions(String selectedWord) {
    setState(() {
      collectedWords.add(selectedWord);
      lastWord = selectedWord;
      context.read<PredictionService>().getPredictions(userId, lastWord);
    });
  }

  void submitPeriod() {
    setState(() {
      collectedWords.add('.');
      lastWord = '.';
      context.read<PredictionService>().getPredictions(userId, lastWord);
    });
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      await _stopRecording();
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    try {
      await context.read<PredictionService>().startRecording(userId);
      setState(() {
        _isRecording = true;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to start recording: $e')),
      );
    }
  }

  Future<void> _stopRecording() async {
    try {
      await context.read<PredictionService>().stopRecording(userId);
      setState(() {
        _isRecording = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to stop recording: $e')),
      );
      setState(() {
        _isRecording = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final predictionService = context.watch<PredictionService>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Predictions'),
        actions: [
          IconButton(
            icon: Icon(_isRecording ? Icons.stop_circle_outlined : Icons.mic),
            onPressed: _toggleRecording,
          ),
        ],
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
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 2,
              ),
              itemCount: predictionService.predictions.length + 1,
              itemBuilder: (context, index) {
                if (index == predictionService.predictions.length) {
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
                  final prediction = predictionService.predictions[index];
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
            ),
          ),
        ],
      ),
    );
  }
}
