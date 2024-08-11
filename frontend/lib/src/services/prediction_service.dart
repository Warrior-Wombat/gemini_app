import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import '../models/prediction.dart';

class PredictionService extends ChangeNotifier {
  final String? baseUrl = dotenv.env['BASE_URL'];
  final Logger _logger = Logger();
  final _audioRecorder = AudioRecorder();
  String? _audioPath;
  bool _isRecording = false;
  List<Prediction> _predictions = [];

  List<Prediction> get predictions => _predictions;

  Future<bool> _requestMicrophonePermission() async {
    PermissionStatus status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<void> startRecording(String userId) async {
    bool permissionGranted = await _requestMicrophonePermission();

    if (permissionGranted) {
      try {
        Directory tempDir = await getTemporaryDirectory();
        _audioPath = '${tempDir.path}/$userId.wav';

        _logger.i('Starting recording with permission granted.');

        if (_audioPath != null) {
          await _audioRecorder.start(const RecordConfig(), path: '$_audioPath');

          _isRecording = true;
          _logger.i('Recording started in memory');
        } else {
          _logger.e('Audio path is null');
          throw Exception('Audio path is null');
        }
      } catch (e) {
        _logger.e('Failed to start recording: $e');
        throw Exception('Failed to start recording: $e');
      }
    } else {
      _logger.e('Microphone permission not granted');
      throw Exception('Microphone permission not granted');
    }
  }

  Future<void> stopRecording(String userId) async {
    if (!_isRecording) {
      _logger.w('Attempted to stop recording when not recording');
      return;
    }

    try {
      await _audioRecorder.stop();
      _isRecording = false;
      _logger.i('Recording stopped, audio file path: $_audioPath');

      if (_audioPath != null) {
        String transcription = await _transcribeAudio();
        await labelResponse(userId, transcription);
      } else {
        throw Exception('No audio data available');
      }
    } catch (e) {
      _logger.e('Error stopping recording: $e');
      throw Exception('Error stopping recording: $e');
    }
  }

  Future<String> _transcribeAudio() async {
    if (_audioPath == null) {
      throw Exception('No audio data available for transcription');
    }

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('https://api.openai.com/v1/audio/transcriptions'),
    );
    request.headers['Authorization'] = 'Bearer ${dotenv.env['OPENAI_API_KEY']}';
    request.fields['model'] = 'whisper-1';
    request.fields['response_format'] = 'json';

    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        _audioPath!,
        contentType: MediaType('audio', 'wav'),
      ),
    );

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);
    _logger.i('openai response: ${response.body}');

    if (response.statusCode == 200) {
      final responseBody = json.decode(response.body);
      _audioPath = null;
      return responseBody['text'];
    } else {
      throw Exception('Failed to transcribe audio: ${response.statusCode}, ${response.body}');
    }
  }

  Future<void> labelResponse(String userId, String transcription) async {
    _logger.i("this is what's being passed into labelResponse: $transcription");
    var response = await http.post(
      Uri.parse('$baseUrl/label_response'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'user_id': userId,
        'transcription': transcription,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to label response: ${response.statusCode}, ${response.body}');
    }

    var responseBody = json.decode(response.body);
    _predictions = (responseBody['predictions'] as List)
        .map((word) => Prediction(word: word.toString()))
        .toList();
    notifyListeners();
  }

  Future<void> getPredictions(String userId, String lastWord) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/user_input'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': userId,
          'input_text': lastWord,
        }),
      );

      _logger.i('Request to /user_input: $baseUrl/user_input, body: ${json.encode({'user_id': userId, 'input_text': lastWord})}');

      if (response.statusCode == 200) {
        Map<String, dynamic> body = json.decode(response.body);

        _logger.i('Response from /user_input: ${response.body}');

        List<Prediction> geminiPredictions = [
          ...(body['gemini_predictions'] as List).map((word) => Prediction(word: word.toString())).toList(),
        ];

        List<Prediction> usageBasedPredictions = [
          ...(body['usage_based_predictions'] as List).map((word) => Prediction(word: word.toString())).toList(),
        ];

        // regex to filter out punctuation, special tokens, duplicates
        _predictions = (geminiPredictions + usageBasedPredictions)
            .map((prediction) => prediction.word)
            .toSet()
            .where((word) => !RegExp(r'[^\w\s]').hasMatch(word) && !['<START>', '<END>'].contains(word))
            .map((word) => Prediction(word: word))
            .toList();

        notifyListeners();
      } else {
        _logger.e('Failed to load predictions: ${response.statusCode}, ${response.body}');
        throw Exception('Failed to load predictions');
      }
    } catch (e) {
      _logger.e('Error getting predictions: $e');
      throw Exception('Error getting predictions: $e');
    }
  }

  Future<void> updateModel(String userId, String selectedWord) async {
    final response = await http.post(
      Uri.parse('$baseUrl/user_input'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'user_id': userId, 'input_text': selectedWord}),
    );

    _logger.i('Request to /user_input for update: $baseUrl/user_input, body: ${json.encode({'user_id': userId, 'input_text': selectedWord})}');

    if (response.statusCode != 200) {
      _logger.e('Failed to update model: ${response.statusCode}, ${response.body}');
      throw Exception('Failed to update model');
    }
  }

  Future<List<String>> handleImageInput(String userId, Uint8List imageData) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/image_input'),
    );

    request.fields['user_id'] = userId;
    request.files.add(http.MultipartFile.fromBytes(
      'file',
      imageData,
      filename: 'image.jpg',
      contentType: MediaType('image', 'jpeg'),
    ));

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode != 200) {
      _logger.e('Failed to handle image input: ${response.statusCode}, $responseBody');
      throw Exception('Failed to handle image input');
    } else {
      _logger.i('Image input handled successfully: $responseBody');
      final jsonResponse = jsonDecode(responseBody);
      return List<String>.from(jsonResponse['predictions']);
    }
  }

  Future<void> endSession(String userId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/end_session'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'user_id': userId}),
    );

    _logger.i('Request to /end_session: $baseUrl/end_session, body: ${json.encode({'user_id': userId})}');

    if (response.statusCode != 200) {
      _logger.e('Failed to end session: ${response.statusCode}, ${response.body}');
      throw Exception('Failed to end session');
    }
  }
  
  Future<Uint8List> speakText(String text) async {
    final apiKey = dotenv.env['ELEVENLABS_API_KEY'];
    final voiceId = 'EXAVITQu4vr4xnSDxMaL';
    final url = 'https://api.elevenlabs.io/v1/text-to-speech/$voiceId';

    final headers = {
      'Accept': 'audio/mpeg',
      'Content-Type': 'application/json',
      'xi-api-key': apiKey!,
    };

    final body = json.encode({
      'text': text,
      'model_id': 'eleven_turbo_v2_5',
      'voice_settings': {
        'stability': 0.5,
        'similarity_boost': 0.5
      }
    });

    final response = await http.post(Uri.parse(url), headers: headers, body: body);

    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      _logger.e('Failed to synthesize speech: ${response.statusCode}, ${response.body}');
      throw Exception('Failed to synthesize speech: ${response.statusCode}, ${response.body}');
    }
  }

  Future<void> deleteWord(String userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/remove_word'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'user_id': userId}),
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> body = json.decode(response.body);
        _predictions = [
          ...(body['gemini_predictions'] as List).map((word) => Prediction(word: word.toString())).toList(),
          ...(body['usage_based_predictions'] as List).map((word) => Prediction(word: word.toString())).toList(),
        ];
        notifyListeners();
      } else {
        _logger.e('Failed to delete word: ${response.statusCode}, ${response.body}');
        throw Exception('Failed to delete word');
      }
    } catch (e) {
      _logger.e('Error deleting word: $e');
      throw Exception('Error deleting word: $e');
    }
  }

  Future<void> sendContext(String userId, String context) async {
    try {
      if (context == '') return; // elevenlabs breathes for some reason when no text is put in
      await updateModel(userId, context);
      final audioBytes = await speakText(context);
      AudioPlayer audioPlayer = AudioPlayer();
      await audioPlayer.play(BytesSource(audioBytes));
      await endSession(userId);
    } catch (e) {
      _logger.e('Error sending context: $e');
      throw Exception('Error sending context: $e');
    }
  }

  @override
  Future<void> dispose() async {
    await _audioRecorder.dispose();
    await endSession(FirebaseAuth.instance.currentUser?.uid ?? 'unauthenticated');
    super.dispose();
  }
}
