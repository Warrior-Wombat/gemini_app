import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/search_service.dart';

class SearchScreen extends StatefulWidget {
  final String userId;
  final ValueChanged<String> onSuggestionSelected;

  SearchScreen({required this.userId, required this.onSuggestionSelected});

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  List<String> _suggestions = [];

  void _onTextChanged(String query) {
    if (query.isNotEmpty) {
      Provider.of<SearchService>(context, listen: false)
          .getSearchPredictions(widget.userId, query)
          .then((suggestions) {
        setState(() {
          _suggestions = suggestions;
        });
      });
    } else {
      setState(() {
        _suggestions = [];
      });
    }
  }

  void _onSend() {
    if (_controller.text.isNotEmpty) {
      widget.onSuggestionSelected(_controller.text);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Search'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Container(
        color: Colors.black,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Search...',
                      hintStyle: TextStyle(color: Colors.white),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide(color: Colors.blueAccent),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide(color: Colors.blueAccent),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide(color: Colors.blueAccent),
                      ),
                    ),
                    style: TextStyle(color: Colors.white),
                    cursorColor: Colors.blueAccent,
                    onChanged: _onTextChanged,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send, color: Colors.blueAccent),
                  onPressed: _onSend,
                ),
              ],
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _suggestions.length,
                itemBuilder: (context, index) {
                  final suggestion = _suggestions[index];
                  return ListTile(
                    title: _buildRichText(suggestion, _controller.text),
                    onTap: () {
                      _controller.text = suggestion;
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRichText(String suggestion, String query) {
    final queryText = query.toLowerCase();
    final suggestionText = suggestion.toLowerCase();
    final startIndex = suggestionText.indexOf(queryText);
    if (startIndex == -1) {
      return Text(suggestion, style: TextStyle(color: Colors.white));
    }
    final endIndex = startIndex + queryText.length;

    return RichText(
      text: TextSpan(
        text: suggestion.substring(0, startIndex),
        style: TextStyle(color: Colors.white),
        children: [
          TextSpan(
            text: suggestion.substring(startIndex, endIndex),
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          TextSpan(
            text: suggestion.substring(endIndex),
            style: TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }
}
