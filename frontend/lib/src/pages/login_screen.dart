import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../components/auth_button.dart';
import '../services/auth_service.dart';
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

  void _login() async {
    setState(() {
      isLoading = true;
    });

    // Simulate a login process
    await Future.delayed(Duration(seconds: 2));

    setState(() {
      isLoading = false;
    });

    // Implement your login logic here
  }

  void _loginWithGoogle() async {
    setState(() {
      isLoading = true;
    });

    try {
      final user = await authService.signInWithGoogle();
      if (user != null) {
        // Handle successful login
      }
    } catch (e) {
      // Handle error
    } finally {
      setState(() {
        isLoading = false;
      });
    }
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
                  },
                ),
              ),
              SizedBox(height: 50),
              Text(
                'Log in to Scale',
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
                ),
                obscureText: true,
                style: TextStyle(color: Colors.white),
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
                isLoading: isLoading,
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
                isLoading: isLoading,
                color: Colors.white,
                textColor: Colors.black,
                width: double.infinity,
                icon: Image.asset('images/google_logo.png', height: 24, width: 24),
                borderColor: Colors.grey.shade600, // Light gray border color
              ),
              SizedBox(height: 16),
              Align(
                alignment: Alignment.center,
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SignUpScreen()),
                    );
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
