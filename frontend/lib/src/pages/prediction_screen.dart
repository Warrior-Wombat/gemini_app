import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../pages/login_screen.dart';
import '../pages/search_screen.dart';
import '../services/auth_service.dart';
import '../services/prediction_service.dart';
import '../services/search_service.dart';

class PredictionScreen extends StatefulWidget {
  @override
  _PredictionScreenState createState() => _PredictionScreenState();
}

class _PredictionScreenState extends State<PredictionScreen> with WidgetsBindingObserver {
  final List<String> collectedWords = [];
  String userId = '';
  String lastWord = '';
  bool _isRecording = false;
  bool _isLoading = false;
  Uint8List? _imageData;
  List<String> _imagePredictions = [];
  final AudioPlayer audioPlayer = AudioPlayer();
  final ScrollController _scrollController = ScrollController();

  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    userId = FirebaseAuth.instance.currentUser?.uid ?? 'unauthenticated';
    Provider.of<PredictionService>(context, listen: false).getPredictions(userId, lastWord);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _callEndSession();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      _callEndSession();
    }
  }

  void _showRateLimitWarning() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Warning'),
          content: Text('You are sending too many requests. Slow down!'),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _callEndSession() async {
    await Provider.of<PredictionService>(context, listen: false).endSession(userId);
  }

  Future<void> updatePredictions(String selectedWord) async {
    setState(() {
      _isLoading = true;
      collectedWords.add(selectedWord);
      lastWord = selectedWord;
    });
    _speakWord(selectedWord);
    try {
      await Provider.of<PredictionService>(context, listen: false).getPredictions(userId, lastWord);
    } catch (e) {
      if (e.toString().contains('429')) {
        _showRateLimitWarning();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to get predictions: $e')),
        );
      }
    }
    setState(() {
      _isLoading = false;
    });
    _scrollToEnd();
  }

  void addPunctuation(String punctuation) {
    setState(() {
      collectedWords.add(punctuation);
      lastWord = punctuation;
    });
    Provider.of<PredictionService>(context, listen: false).getPredictions(userId, lastWord);
    _scrollToEnd();
  }

  void deleteWord() async {
    if (collectedWords.isNotEmpty) {
      await Provider.of<PredictionService>(context, listen: false).deleteWord(userId);
      setState(() {
        collectedWords.removeLast();
        lastWord = collectedWords.isNotEmpty ? collectedWords.last : '';
      });
      Provider.of<PredictionService>(context, listen: false).getPredictions(userId, lastWord);
      _scrollToEnd();
    }
  }

  void sendContext() async {
    String collectedContext = collectedWords.join(' ');
    await Provider.of<PredictionService>(context, listen: false).sendContext(userId, collectedContext);
    setState(() {
      collectedWords.clear();
      lastWord = '';
    });
    Provider.of<PredictionService>(context, listen: false).getPredictions(userId, lastWord);
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
      await Provider.of<PredictionService>(context, listen: false).startRecording(userId);
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
      await Provider.of<PredictionService>(context, listen: false).stopRecording(userId);
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

    _showLoadingModal();

    try {
      final predictions = await Provider.of<PredictionService>(context, listen: false).handleImageInput(userId, bytes);
      setState(() {
        _imagePredictions = predictions;
      });
      Navigator.of(context).pop();
      _showImagePredictionsModal();
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to process image: $e')),
      );
    }
  }

  void _showLoadingModal() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            padding: EdgeInsets.all(16),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          ),
        );
      },
    );
  }

  void _showImagePredictionsModal() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                if (_imageData != null)
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.blueAccent, width: 4),
                      ),
                      child: Image.memory(
                        _imageData!,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _imagePredictions.map((prediction) {
                      return GestureDetector(
                        onTap: () {
                          Navigator.of(context).pop();
                          _addImagePrediction(prediction);
                        },
                        child: Container(
                          margin: EdgeInsets.symmetric(horizontal: 4),
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            border: Border.all(color: Colors.blueAccent, width: 2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            prediction,
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Close'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _addImagePrediction(String prediction) {
    setState(() {
      collectedWords.add(prediction);
      lastWord = prediction;
    });
    _speakWord(prediction);
    Provider.of<PredictionService>(context, listen: false).getPredictions(userId, lastWord);
  }
  
  Future<void> _speakWord(String word) async {
    try {
      final audioBytes = await Provider.of<PredictionService>(context, listen: false).speakText(word);
      await audioPlayer.play(BytesSource(audioBytes));
    } catch (e) {
      if (e.toString().contains('429')) {
        _showRateLimitWarning();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to speak word: $e')),
        );
      }
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  void _handleIconSelected(Function action) {
    action();
  }

  Future<void> _logOut() async {
    try {
      await Provider.of<AuthService>(context, listen: false).logOut();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to log out: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final predictionService = Provider.of<PredictionService>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final List<String> punctuationTiles = ['.', ',', '?', '!']; // punctuation stays constant, gemini recommending punctuation is a waste of space

    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          AnimatedContainer(
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: _isExpanded ? screenWidth * 0.8 : 48,
            alignment: _isExpanded ? Alignment.centerRight : Alignment.center,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (_isExpanded)
                    Flexible(
                      fit: FlexFit.loose,
                      child: IconButton(
                        icon: Icon(Icons.logout),
                        onPressed: _logOut,
                        color: Colors.white,
                      ),
                    ),
                  if (_isExpanded)
                    Flexible(
                      fit: FlexFit.loose,
                      child: IconButton(
                        icon: Icon(Icons.search),
                        onPressed: () => _handleIconSelected(() {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => ChangeNotifierProvider<SearchService>(
                                create: (_) => SearchService(),
                                child: SearchScreen(
                                  userId: userId,
                                  onSuggestionSelected: (selectedSuggestion) {
                                    updatePredictions(selectedSuggestion);
                                  },
                                ),
                              ),
                            ),
                          );
                        }),
                        color: Colors.white,
                      ),
                    ),
                  if (_isExpanded)
                    Flexible(
                      fit: FlexFit.loose,
                      child: IconButton(
                        icon: Icon(Icons.camera_alt),
                        onPressed: () => _handleIconSelected(_captureImage),
                        color: Colors.white,
                      ),
                    ),
                  if (_isExpanded)
                    Flexible(
                      fit: FlexFit.loose,
                      child: IconButton(
                        icon: Icon(Icons.photo),
                        onPressed: () => _handleIconSelected(_pickImage),
                        color: Colors.white,
                      ),
                    ),
                  if (_isExpanded)
                    Flexible(
                      fit: FlexFit.loose,
                      child: IconButton(
                        icon: Icon(_isRecording ? Icons.stop_circle_outlined : Icons.mic),
                        onPressed: () => _handleIconSelected(_toggleRecording),
                        color: Colors.white,
                      ),
                    ),
                  AnimatedSwitcher(
                    duration: Duration(milliseconds: 300),
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      return RotationTransition(
                        turns: child.key == ValueKey('close') ? Tween(begin: 0.0, end: 0.25).animate(animation) : animation,
                        child: child,
                      );
                    },
                    child: IconButton(
                      key: ValueKey(_isExpanded ? 'close' : 'add'),
                      icon: Icon(_isExpanded ? Icons.close : Icons.add_circle),
                      onPressed: _toggleExpanded,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Container(
        color: Colors.black,
        child: Column(
          children: [
            Container(
              height: 80,
              width: screenWidth - 32,
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              padding: EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.black,
                border: Border.all(color: Colors.blueAccent, width: 2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                children: [
                  SingleChildScrollView(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    child: Padding(
                      padding: EdgeInsets.only(right: 48),
                      child: Center(
                        child: Text(
                          collectedWords.join(' '),
                          style: TextStyle(fontSize: 24, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    child: IconButton(
                      icon: Icon(Icons.backspace, color: Colors.white),
                      onPressed: deleteWord,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: EdgeInsets.all(16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 1,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: predictionService.predictions.length + punctuationTiles.length,
                itemBuilder: (context, index) {
                  if (index < predictionService.predictions.length) {
                    final prediction = predictionService.predictions[index];
                    return GestureDetector(
                      onTap: _isLoading ? null : () async {
                        await updatePredictions(prediction.word);
                      },
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: Colors.blueAccent, width: 2),
                        ),
                        elevation: 10,
                        color: Colors.black,
                        child: Center(
                          child: _isLoading
                              ? CircularProgressIndicator()
                              : Text(
                                  prediction.word,
                                  style: GoogleFonts.roboto(
                                    color: Colors.white,
                                    fontSize: 18,
                                  ),
                                ),
                        ),
                      ),
                    );
                  } else {
                    final punctuation = punctuationTiles[index - predictionService.predictions.length];
                    return GestureDetector(
                      onTap: _isLoading ? null : () {
                        addPunctuation(punctuation);
                      },
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: Colors.blueAccent, width: 2),
                        ),
                        elevation: 10,
                        color: Colors.black,
                        child: Center(
                          child: Text(
                            punctuation,
                            style: GoogleFonts.roboto(
                              color: Colors.white,
                              fontSize: 18),
                          ),
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
            Container(
              width: screenWidth - 32,
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: ElevatedButton.icon(
                icon: Icon(Icons.send),
                label: Text('Send'),
                onPressed: _isLoading ? null : sendContext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
