import 'dart:math';
import 'package:flutter/material.dart';

class FocusRingGame extends StatefulWidget {
  const FocusRingGame({super.key});

  @override
  State<FocusRingGame> createState() => _FocusRingGameState();
}

class _FocusRingGameState extends State<FocusRingGame>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _score = 0;
  bool _hit = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    final value = _controller.value;

    // Sweet zone (centered)
    if (value > 0.42 && value < 0.58) {
      setState(() {
        _score++;
        _hit = true;
      });
    } else {
      setState(() {
        _score = max(0, _score - 1);
        _hit = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) {
          final scale = 1.0 - (_controller.value * 0.6);

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Focus Ring",
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),

              Transform.scale(
                scale: scale,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      width: 6,
                      color: _hit
                          ? Colors.greenAccent
                          : Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Text(
                "Score: $_score",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                "Tap when the ring is centered",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          );
        },
      ),
    );
  }
}
