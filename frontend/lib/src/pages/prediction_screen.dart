import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../services/prediction_service.dart';

class PredictionScreen extends StatefulWidget {
  @override
  _PredictionScreenState createState() => _PredictionScreenState();
}

class _PredictionScreenState extends State<PredictionScreen> {
  final List<String> collectedWords = [];
  List<String> defaultWords = ["Hello", "Hi", "Hey", "Good", "How", "What", "When", "Where", "Why"];
  String userId = '';
  String lastWord = '';
  bool _isRecording = false;
  Uint8List? _imageData;
  List<String> _imagePredictions = [];

  @override
  void initState() {
    super.initState();
    userId = FirebaseAuth.instance.currentUser?.uid ?? 'unauthenticated';
    context.read<PredictionService>().getPredictions(userId, lastWord);
  }

  @override
  void dispose() {
    _callEndSession();
    super.dispose();
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

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        await _processImage(bytes);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
    }
  }

  Future<void> _captureImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.camera);

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        await _processImage(bytes);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to capture image: $e')),
      );
    }
  }

  Future<void> _processImage(Uint8List bytes) async {
    setState(() {
      _imageData = bytes;
    });

    try {
      final predictions = await context.read<PredictionService>().handleImageInput(userId, bytes);
      setState(() {
        _imagePredictions = predictions;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to process image: $e')),
      );
    }
  }

  void _addImagePrediction(String prediction) {
    setState(() {
      collectedWords.add(prediction);
      lastWord = prediction;
      context.read<PredictionService>().getPredictions(userId, lastWord);
    });
  }

  @override
  Widget build(BuildContext context) {
    final predictionService = context.watch<PredictionService>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Predictions'),
        actions: [
          IconButton(
            icon: Icon(Icons.camera_alt),
            onPressed: _captureImage,
          ),
          IconButton(
            icon: Icon(Icons.photo),
            onPressed: _pickImage,
          ),
          IconButton(
            icon: Icon(_isRecording ? Icons.stop_circle_outlined : Icons.mic),
            onPressed: _toggleRecording,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_imageData != null) ...[
            Container(
              margin: EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 4),
              ),
              child: Image.memory(
                _imageData!,
                height: 200,
                fit: BoxFit.cover,
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _imagePredictions.map((prediction) {
                  return GestureDetector(
                    onTap: () => _addImagePrediction(prediction),
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 4),
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        prediction,
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
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
