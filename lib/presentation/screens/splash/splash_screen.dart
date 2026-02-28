import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final AnimationController _glowController;

  late final Animation<double> _fadeIn;
  late final Animation<double> _glowPulse;

  @override
  void initState() {
    super.initState();

    // ─────────────────────────────
    // Fade-in (logo + text)
    // ─────────────────────────────
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeIn = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );

    // ─────────────────────────────
    // Glow pulse (subtle, infinite)
    // ─────────────────────────────
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);

    _glowPulse = CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    );

    _fadeController.forward();

    // ─────────────────────────────
    // Auto-navigate after warm-up
    // (crypto already tested in main)
    // ─────────────────────────────
    Timer(const Duration(milliseconds: 2200), () {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/login');
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D12),
      body: Stack(
        children: [
          _backgroundGlow(),
          Center(child: _content()),
        ],
      ),
    );
  }

  // ─────────────────────────────
  // Background glow (brand accent)
  // ─────────────────────────────
  Widget _backgroundGlow() {
    return AnimatedBuilder(
      animation: _glowPulse,
      builder: (_, __) {
        return Positioned.fill(
          child: Opacity(
            opacity: 0.18 + (_glowPulse.value * 0.08),
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  radius: 0.8,
                  colors: [
                    Color(0xFF9255E8),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ─────────────────────────────
  // Center content
  // ─────────────────────────────
  Widget _content() {
    return FadeTransition(
      opacity: _fadeIn,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _logoText(),
          const SizedBox(height: 16),
          _tagline(),
          const SizedBox(height: 32),
          _loadingIndicator(),
        ],
      ),
    );
  }

  // ─────────────────────────────
  // Silvora logo (text-based)
  // ─────────────────────────────
  Widget _logoText() {
    return RichText(
      text: const TextSpan(
        style: TextStyle(
          fontSize: 42,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
          color: Colors.white,
        ),
        children: [
          TextSpan(text: "Silvora"),
          TextSpan(
            text: ".",
            style: TextStyle(
              color: Color(0xFF9255E8),
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────
  // Tagline
  // ─────────────────────────────
  Widget _tagline() {
    return const Text(
      "Your Cloud. Your Control.",
      style: TextStyle(
        color: Colors.white70,
        fontSize: 14,
        letterSpacing: 0.3,
      ),
    );
  }

  // ─────────────────────────────
  // Custom loading indicator
  // (crypto-style, not Material)
  // ─────────────────────────────
  Widget _loadingIndicator() {
    return SizedBox(
      width: 42,
      height: 42,
      child: AnimatedBuilder(
        animation: _glowPulse,
        builder: (_, __) {
          return Transform.rotate(
            angle: _glowPulse.value * 2 * math.pi,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              valueColor: AlwaysStoppedAnimation<Color>(
                const Color(0xFF9255E8)
                    .withValues(alpha: 0.6 + (_glowPulse.value * 0.4)),
              ),
            ),
          );
        },
      ),
    );
  }
}
