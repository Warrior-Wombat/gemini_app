import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../components/auth_button.dart';
import '../services/auth_service.dart';
import 'prediction_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final AuthService authService = AuthService();
  bool isLoading = false;
  String errorMessage = '';
  bool emailError = false;
  bool passwordError = false;
  bool showError = false;
  String activeButton = '';

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    setState(() {
      isLoading = true;
      activeButton = 'login';
      errorMessage = '';
      showError = false;
      emailError = false;
      passwordError = false;
    });

    try {
      final user = await authService.signInWithEmailAndPassword(
        emailController.text,
        passwordController.text,
      );
      if (user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => PredictionScreen()),
        );
      }
    } catch (e) {
      setState(() {
        errorMessage = _parseFirebaseAuthErrorMessage(e.toString());
        showError = true;
        emailError = true;
        passwordError = true;
      });
    } finally {
      setState(() {
        isLoading = false;
        activeButton = '';
      });
    }
  }

  void _loginWithGoogle() async {
    setState(() {
      isLoading = true;
      activeButton = 'google';
      errorMessage = '';
      showError = false;
      emailError = false;
      passwordError = false;
    });

    try {
      final user = await authService.signInWithGoogle();
      if (user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => PredictionScreen()),
        );
      }
    } catch (e) {
      setState(() {
        errorMessage = _parseFirebaseAuthErrorMessage(e.toString());
        showError = true;
      });
    } finally {
      setState(() {
        isLoading = false;
        activeButton = '';
      });
    }
  }

  String _parseFirebaseAuthErrorMessage(String error) {
    final regex = RegExp(r'\[.*?\]\s(.*)');
    final match = regex.firstMatch(error);
    return match != null ? match.group(1)! : 'An unknown error occurred.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false,
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 50),
              Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  icon: Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {
                      errorMessage = '';
                      showError = false;
                    });
                  },
                ),
              ),
              SizedBox(height: 50),
              Text(
                'Log in to SaySpeak',
                style: GoogleFonts.roboto(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 24),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: TextStyle(color: Colors.white),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  errorBorder: emailError ? OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.red),
                  ) : OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
                style: TextStyle(color: Colors.white),
              ),
              SizedBox(height: 16),
              TextField(
                controller: passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  labelStyle: TextStyle(color: Colors.white),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  errorBorder: passwordError ? OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.red),
                  ) : OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
                obscureText: true,
                style: TextStyle(color: Colors.white),
              ),
              AnimatedOpacity(
                opacity: showError ? 1.0 : 0.0,
                duration: Duration(milliseconds: 500),
                child: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    errorMessage,
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ),
              SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    // Handle password reset
                  },
                  child: Text(
                    'Forgot Password?',
                    style: TextStyle(color: Colors.green),
                  ),
                ),
              ),
              SizedBox(height: 16),
              AuthButton(
                text: 'Login',
                onPressed: _login,
                isLoading: isLoading && activeButton == 'login',
                color: Colors.white,
                textColor: Colors.black,
                width: double.infinity,
              ),
              SizedBox(height: 16),
              Divider(color: Colors.white),
              SizedBox(height: 16),
              AuthButton(
                text: 'Continue with Google',
                onPressed: _loginWithGoogle,
                isLoading: isLoading && activeButton == 'google',
                color: Colors.white,
                textColor: Colors.black,
                width: double.infinity,
                icon: Image.asset('images/google_logo.png', height: 24, width: 24),
                borderColor: Colors.grey.shade600,
              ),
              SizedBox(height: 16),
              Align(
                alignment: Alignment.center,
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SignUpScreen()),
                    ).then((_) {
                      setState(() {
                        errorMessage = '';
                        showError = false;
                      });
                    });
                  },
                  child: Text(
                    'Don\'t have an account? Sign Up',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
