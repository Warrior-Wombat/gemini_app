import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'prediction_screen.dart';

class InfoScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome to SaySpeak', style: GoogleFonts.roboto(color: Colors.white)),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: Icon(Icons.close, color: Colors.white),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => PredictionScreen()),
              );
            },
          ),
        ],
      ),
      body: Container(
        color: Colors.black,
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This app is for nonverbal people.',
                style: GoogleFonts.roboto(color: Colors.white, fontSize: 18),
              ),
              SizedBox(height: 16),
              Text(
                'Icons Explanation:',
                style: GoogleFonts.roboto(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              _buildIconExplanation(Icons.add_circle, 'Plus Circle', 'Expands the menu to show more options.'),
              _buildIconExplanation(Icons.mic, 'Microphone', 'Allows voice input from the person you are talking to add predictions.'),
              _buildIconExplanation(Icons.camera_alt, 'Camera', 'Opens the camera to capture an image.'),
              _buildIconExplanation(Icons.photo, 'Photo', 'Opens the gallery to pick an image.'),
              _buildIconExplanation(Icons.search, 'Search', 'Opens the search screen to find predictions.'),
              _buildIconExplanation(Icons.send, 'Send', 'Sends the current context.'),
              _buildIconExplanation(Icons.backspace, 'Backspace', 'Deletes the last word.'),
              _buildIconExplanation(Icons.logout, 'Logout', 'Logs out of the application.'),
              SizedBox(height: 16),
              Text(
                'General Instructions:',
                style: GoogleFonts.roboto(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                '1. Use the Plus Circle icon to expand the menu and access more options.\n'
                '2. Use the Microphone icon to input voice predictions.\n'
                '3. Use the Camera icon to capture images.\n'
                '4. Use the Photo icon to select images from the gallery.\n'
                '5. Use the Search icon to find specific predictions.\n'
                '6. Use the Send icon to send the current context.\n'
                '7. Use the Backspace icon to delete the last word.\n'
                '8. Use the Logout icon to log out of the application.',
                style: GoogleFonts.roboto(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconExplanation(IconData icon, String iconName, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueAccent, size: 24),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              '$iconName: $description',
              style: GoogleFonts.roboto(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
