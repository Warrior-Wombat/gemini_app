import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'services/gemini_service.dart';
import 'services/google_auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Obtain Vertex AI API access token
  final googleAuthService = GoogleAuthService();
  final accessToken = await googleAuthService.getAccessToken();
  print('Gemini API Access Token: $accessToken');

  runApp(MyApp(accessToken: accessToken));
}

class MyApp extends StatelessWidget {
  final String accessToken;
  const MyApp({Key? key, required this.accessToken}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Autocomplete',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: MyHomePage(accessToken: accessToken),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final String accessToken;
  const MyHomePage({Key? key, required this.accessToken}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _controller = TextEditingController();
  List<String> _predictions = [];

  @override
  void initState() {
    super.initState();
    _controller.addListener(_fetchPredictions);
  }

  @override
  void dispose() {
    _controller.removeListener(_fetchPredictions);
    _controller.dispose();
    super.dispose();
  }

  void _fetchPredictions() async {
    final input = _controller.text;
    if (input.isEmpty) {
      setState(() {
        _predictions = _getInitialWords();
      });
    } else {
      try {
        final predictions = await GeminiService(widget.accessToken).predictNextWords(input);
        setState(() {
          _predictions = predictions;
        });
      } catch (e) {
        print('Error fetching predictions: $e');
        setState(() {
          _predictions = ['Error fetching predictions'];
        });
      }
    }
  }

  List<String> _getInitialWords() {
    return ["I", "You", "He", "She", "It", "We", "They", "This", "That"];
  }

  void _onWordTap(String word) {
    setState(() {
      _controller.text += ' $word';
      _controller.selection = TextSelection.fromPosition(TextPosition(offset: _controller.text.length));
      _fetchPredictions(); // Fetch new predictions after word is added
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text('Autocomplete Demo'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Start typing...',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            Expanded(
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                ),
                itemCount: _predictions.length,
                itemBuilder: (context, index) {
                  return ElevatedButton(
                    onPressed: () {
                      _onWordTap(_predictions[index]);
                    },
                    child: Text(_predictions[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}