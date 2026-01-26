import 'package:flutter/material.dart';

class CalmOrbGame extends StatefulWidget {
  const CalmOrbGame({super.key});

  @override
  State<CalmOrbGame> createState() => _CalmOrbGameState();
}

class _CalmOrbGameState extends State<CalmOrbGame>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  bool _inhale = true;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _scale = Tween<double>(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _inhale = false);
        _controller.reverse();
      } else if (status == AnimationStatus.dismissed) {
        setState(() => _inhale = true);
        _controller.forward();
      }
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _scale,
            builder: (_, __) {
              return Transform.scale(
                scale: _scale.value,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.35),
                        Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.15),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 20),

          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            child: Text(
              _inhale ? "Breathe in…" : "Breathe out…",
              key: ValueKey(_inhale),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color.fromARGB(255, 137, 75, 252),
              ),
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            "Uploading securely",
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
