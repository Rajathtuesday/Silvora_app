// lib/screens/billing/billing_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../../services/api_services.dart';
import '../../theme/silvora_theme.dart';

class _Plan {
  final String tier; // "pro" | "enterprise"
  final String interval; // "monthly" | "yearly"
  final String label;
  final String storage;
  final String price;

  const _Plan({
    required this.tier,
    required this.interval,
    required this.label,
    required this.storage,
    required this.price,
  });
}

/// Static pricing copy mirroring what's actually configured server-side in
/// RazorpayPlan — if these ever drift apart, /api/billing/subscribe/ already
/// returns a clean "not configured yet" error rather than crashing.
const _plans = [
  _Plan(tier: "pro", interval: "monthly", label: "Pro", storage: "100GB", price: "₹199/mo"),
  _Plan(tier: "pro", interval: "yearly", label: "Pro", storage: "100GB", price: "₹1,990/yr"),
  _Plan(tier: "enterprise", interval: "monthly", label: "Enterprise", storage: "1TB", price: "₹599/mo"),
  _Plan(tier: "enterprise", interval: "yearly", label: "Enterprise", storage: "1TB", price: "₹5,990/yr"),
];

class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  late Razorpay _razorpay;
  Future<Map<String, dynamic>>? _quotaFuture;
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

  Future<void> _subscribe(_Plan plan) async {
    setState(() {
      _error = null;
      _subscribingTier = plan.tier;
      _subscribingInterval = plan.interval;
    });

    try {
      final result = await ApiService.createSubscription(plan.tier, plan.interval);
      _razorpay.open({
        'key': result["razorpay_key_id"],
        'subscription_id': result["subscription_id"],
        'name': 'Silvora',
        'description': '${plan.label} (${plan.interval})',
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
            const SizedBox(height: 12),
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
            for (final plan in _plans) _buildPlanCard(plan),
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

  Widget _buildPlanCard(_Plan plan) {
    final isSubscribing = _subscribingTier == plan.tier && _subscribingInterval == plan.interval;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SilvoraColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SilvoraColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("${plan.label} · ${plan.storage}",
                    style: const TextStyle(color: SilvoraColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 4),
                Text(plan.price, style: const TextStyle(color: SilvoraColors.textSecondary, fontSize: 13)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: _subscribingTier != null ? null : () => _subscribe(plan),
            child: isSubscribing
                ? const SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text("Subscribe"),
          ),
        ],
      ),
    );
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
