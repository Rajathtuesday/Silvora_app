// lib/screens/billing/billing_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../../services/api_services.dart';
import '../../theme/silvora_theme.dart';

class _Tier {
  final String tier; // "pro" | "enterprise"
  final String label;
  final String storage;
  final int monthlyPrice; // rupees
  final int yearlyPrice; // rupees
  final bool premium; // gets the gold treatment

  const _Tier({
    required this.tier,
    required this.label,
    required this.storage,
    required this.monthlyPrice,
    required this.yearlyPrice,
    this.premium = false,
  });
}

/// Static pricing copy mirroring what's actually configured server-side in
/// RazorpayPlan — if these ever drift apart, /api/billing/subscribe/ already
/// returns a clean "not configured yet" error rather than crashing.
/// Yearly is exactly 10x monthly for both tiers — i.e. 2 months free.
const _tiers = [
  _Tier(tier: "pro", label: "Pro", storage: "100GB", monthlyPrice: 199, yearlyPrice: 1990),
  _Tier(tier: "enterprise", label: "Enterprise", storage: "1TB", monthlyPrice: 599, yearlyPrice: 5990, premium: true),
];

class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  late Razorpay _razorpay;
  Future<Map<String, dynamic>>? _quotaFuture;
  String _interval = "monthly"; // toggle shared by both tier cards
  String? _subscribingTier; // which card's button is mid-flight, for a per-card spinner
  String? _subscribingInterval;
  String? _error;

  @override
  void initState() {
    super.initState();
    _quotaFuture = ApiService.getQuota();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  Future<void> _subscribe(_Tier tier) async {
    setState(() {
      _error = null;
      _subscribingTier = tier.tier;
      _subscribingInterval = _interval;
    });

    try {
      final result = await ApiService.createSubscription(tier.tier, _interval);
      _razorpay.open({
        'key': result["razorpay_key_id"],
        'subscription_id': result["subscription_id"],
        'name': 'Silvora',
        'description': '${tier.label} ($_interval)',
        'theme': {'color': '#5B4FE8'},
      });
      // Deliberately not resetting _subscribingTier here — the checkout
      // sheet is now in front of this screen; the spinner state doesn't
      // matter again until a Razorpay event fires below.
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst("Exception: ", "");
        _subscribingTier = null;
        _subscribingInterval = null;
      });
    }
  }

  void _onPaymentSuccess(PaymentSuccessResponse response) {
    if (!mounted) return;
    setState(() {
      _subscribingTier = null;
      _subscribingInterval = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Payment received — activating your subscription…")),
    );
    // The actual tier upgrade happens server-side via Razorpay's webhook,
    // independent of this app. The SDK callback only confirms checkout
    // succeeded, not that the webhook has landed yet — give it a moment,
    // then re-fetch quota so the screen reflects the real, server-confirmed
    // tier rather than assuming success from the callback alone.
    Future.delayed(const Duration(seconds: 4), () {
      if (!mounted) return;
      setState(() => _quotaFuture = ApiService.getQuota());
    });
  }

  void _onPaymentError(PaymentFailureResponse response) {
    if (!mounted) return;
    setState(() {
      _subscribingTier = null;
      _subscribingInterval = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Payment failed: ${response.message ?? 'cancelled'}")),
    );
  }

  void _onExternalWallet(ExternalWalletResponse response) {
    if (!mounted) return;
    setState(() {
      _subscribingTier = null;
      _subscribingInterval = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Manage Subscription")),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildCurrentPlanCard(),
            const SizedBox(height: 24),
            Text(
              "Plans",
              style: GoogleFonts.syne(fontSize: 18, fontWeight: FontWeight.w700, color: SilvoraColors.textPrimary),
            ),
            const SizedBox(height: 14),
            _buildIntervalToggle(),
            const SizedBox(height: 16),
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: SilvoraColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: SilvoraColors.error.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: SilvoraColors.error, size: 18),
                    const SizedBox(width: 10),
                    Expanded(child: Text(_error!, style: const TextStyle(color: SilvoraColors.error, fontSize: 13))),
                  ],
                ),
              ),
            ],
            for (final tier in _tiers) _buildTierCard(tier),
          ],
        ),
      ),
    );
  }

  Widget _buildIntervalToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: SilvoraColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SilvoraColors.border),
      ),
      child: Row(
        children: [
          Expanded(child: _intervalOption("monthly", "Monthly")),
          Expanded(child: _intervalOption("yearly", "Yearly", badge: "2 months free")),
        ],
      ),
    );
  }

  Widget _intervalOption(String value, String label, {String? badge}) {
    final selected = _interval == value;
    return GestureDetector(
      onTap: () => setState(() => _interval = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? SilvoraColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: selected ? Colors.white : SilvoraColors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            if (badge != null) ...[
              const SizedBox(height: 2),
              Text(
                badge,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: selected ? Colors.white.withValues(alpha: 0.85) : SilvoraColors.gold,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentPlanCard() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _quotaFuture,
      builder: (ctx, snap) {
        final tier = (snap.data?["tier"] as String?) ?? "free";
        final used = (snap.data?["used"] as int?) ?? 0;
        final limit = (snap.data?["limit"] as int?) ?? 0;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: SilvoraColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: SilvoraColors.border),
          ),
          child: Row(
            children: [
              const Icon(Icons.workspace_premium_outlined, color: SilvoraColors.gold, size: 28),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Current plan: ${tier[0].toUpperCase()}${tier.substring(1)}",
                        style: const TextStyle(color: SilvoraColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 4),
                    Text(snap.connectionState == ConnectionState.waiting
                        ? "Loading usage…"
                        : "${_formatBytes(used)} of ${_formatBytes(limit)} used",
                        style: const TextStyle(color: SilvoraColors.textMuted, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTierCard(_Tier tier) {
    final isSubscribing = _subscribingTier == tier.tier && _subscribingInterval == _interval;
    final isYearly = _interval == "yearly";
    final priceRupees = isYearly ? tier.yearlyPrice : tier.monthlyPrice;
    final monthlyEquivalent = (tier.yearlyPrice / 12).round();
    final accent = tier.premium ? SilvoraColors.gold : SilvoraColors.primaryLight;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: SilvoraColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tier.premium ? SilvoraColors.gold.withValues(alpha: 0.45) : SilvoraColors.border, width: tier.premium ? 1.4 : 1),
        boxShadow: tier.premium
            ? [BoxShadow(color: SilvoraColors.gold.withValues(alpha: 0.08), blurRadius: 18, spreadRadius: 1)]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  tier.label.toUpperCase(),
                  style: TextStyle(color: accent, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.6),
                ),
              ),
              const SizedBox(width: 8),
              Text(tier.storage, style: const TextStyle(color: SilvoraColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
              if (tier.premium) ...[
                const Spacer(),
                const Icon(Icons.workspace_premium, color: SilvoraColors.gold, size: 18),
              ],
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                "₹${_withCommas(priceRupees)}",
                style: GoogleFonts.syne(color: SilvoraColors.textPrimary, fontSize: 30, fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 4),
              Text(isYearly ? "/yr" : "/mo", style: const TextStyle(color: SilvoraColors.textMuted, fontSize: 14)),
            ],
          ),
          if (isYearly) ...[
            const SizedBox(height: 4),
            Text("≈ ₹$monthlyEquivalent/mo · billed yearly", style: const TextStyle(color: SilvoraColors.textMuted, fontSize: 12)),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: tier.premium
                  ? ElevatedButton.styleFrom(backgroundColor: SilvoraColors.gold, foregroundColor: const Color(0xFF1A1408))
                  : null,
              onPressed: _subscribingTier != null ? null : () => _subscribe(tier),
              child: isSubscribing
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text("Subscribe to ${tier.label}"),
            ),
          ),
        ],
      ),
    );
  }

  String _withCommas(int n) {
    final s = n.toString();
    if (s.length <= 3) return s;
    final head = s.substring(0, s.length - 3);
    final tail = s.substring(s.length - 3);
    final headWithCommas = head.replaceAllMapped(RegExp(r'(\d)(?=(\d{2})+(?!\d))'), (m) => '${m[1]},');
    return '$headWithCommas,$tail';
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return "0 B";
    const units = ["B", "KB", "MB", "GB", "TB"];
    var size = bytes.toDouble();
    var i = 0;
    while (size >= 1024 && i < units.length - 1) {
      size /= 1024;
      i++;
    }
    return "${size.toStringAsFixed(size < 10 && i > 0 ? 1 : 0)} ${units[i]}";
  }
}
