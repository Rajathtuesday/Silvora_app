import 'package:flutter/material.dart';

class SilvoraLogo extends StatelessWidget {
  final double fontSize;
  final Color? color;

  const SilvoraLogo({
    super.key,
    this.fontSize = 22,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w700,
          fontSize: fontSize,
          color: color ?? Theme.of(context).colorScheme.onSurface,
        ),
        children: const [
          TextSpan(text: 'Silvora'),
          TextSpan(
            text: '.',
            style: TextStyle(
              color: Color(0xFF9255E8),
            ),
          ),
        ],
      ),
    );
  }
}
