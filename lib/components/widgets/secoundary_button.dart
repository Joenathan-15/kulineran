import 'package:flutter/material.dart';

class SecoundaryButton extends StatelessWidget {
  final String text;
  final Function() onPressed;
  final double? width;
  const SecoundaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? 370 ,
      height: 50,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          backgroundColor: const Color(0xFF1C1B1B),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
