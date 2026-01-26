import 'dart:async';
import 'package:flutter/material.dart';

class ReflexGame extends StatefulWidget {
  const ReflexGame({super.key});

  @override
  State<ReflexGame> createState() => _ReflexGameState();
}

class _ReflexGameState extends State<ReflexGame> {
  int _score = 0;
  double _scale = 1.0;
  Duration _duration = const Duration(milliseconds: 1200);
  Timer? _timer;

  void _startRound() {
    _timer?.cancel();

    setState(() {
      _scale = 1.0;
    });

    _timer = Timer(const Duration(milliseconds: 50), () {
      if (!mounted) return;
      setState(() {
        _scale = 0.0;
      });
    });
  }

  void _onTap() {
    _timer?.cancel();

    setState(() {
      _score++;
      _duration = Duration(
        milliseconds: (_duration.inMilliseconds * 0.92).clamp(400, 1200).toInt(),
      );
    });

    _startRound();
  }

  void _onMiss() {
    _timer?.cancel();

    setState(() {
      _score = 0;
      _duration = const Duration(milliseconds: 1200);
    });

    _startRound();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startRound());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Score: $_score",
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),

        GestureDetector(
          onTap: _onTap,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 1.0, end: _scale),
            duration: _duration,
            onEnd: _scale == 0.0 ? _onMiss : null,
            builder: (context, value, _) {
              return Transform.scale(
                scale: value,
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      colors: [
                        Color(0xFF7C4DFF),
                        Color(0xFF512DA8),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.deepPurple.withOpacity(0.4),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 12),
        const Text(
          "Tap before it vanishes",
          style: TextStyle(color: Colors.grey),
        ),
      ],
    );
  }
}
// =====================================================