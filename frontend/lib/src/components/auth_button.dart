import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';

class AuthButton extends StatefulWidget {
  final String text;
  final Function() onPressed;
  final bool isLoading;
  final Color color;
  final Color textColor;
  final double width;
  final Widget? icon;
  final Color borderColor;

  AuthButton({
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.color = Colors.white,
    this.textColor = Colors.black,
    this.width = double.infinity,
    this.icon,
    this.borderColor = Colors.transparent,
  });

  @override
  _AuthButtonState createState() => _AuthButtonState();
}

class _AuthButtonState extends State<AuthButton> with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      decoration: BoxDecoration(
        border: Border.all(color: widget.borderColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ElevatedButton(
        onPressed: widget.isLoading ? null : widget.onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: widget.color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: EdgeInsets.symmetric(vertical: 16),
        ),
        child: widget.isLoading
            ? SpinKitThreeBounce(
                color: widget.textColor,
                size: 20.0,
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.icon != null) ...[
                    widget.icon!,
                    SizedBox(width: 8),
                  ],
                  Text(
                    widget.text,
                    style: GoogleFonts.roboto(
                      color: widget.textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
