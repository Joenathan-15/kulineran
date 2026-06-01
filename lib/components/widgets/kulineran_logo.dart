import 'package:flutter/material.dart';

class KulineranLogo extends StatelessWidget {
  final double fontSize;
  final MainAxisAlignment alignment;

  const KulineranLogo({
    super.key,
    this.fontSize = 24,
    this.alignment = MainAxisAlignment.center,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "KULINE",
          style: TextStyle(
            
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: const Color(0xFFFF7260), // Coral red/orange
          ),
        ),
        Text(
          "RAN",
          style: TextStyle(
            
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: const Color(0xFFFFB300), // Golden yellow
          ),
        ),
      ],
    );
  }
}
