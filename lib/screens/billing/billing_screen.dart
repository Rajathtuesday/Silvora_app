// lib/screens/billing/billing_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/api_services.dart';
import '../../theme/silvora_theme.dart';

class _Tier {
  final String tier; // "pro" | "enterprise"
  final String label;
  final String storage;
  final int monthlyPrice; // rupees
  final int yearlyPrice; // rupees
  final bool premium; // gets the gold treatment
  final String playProductId; // e.g. "silvora_pro" -- must mirror PlayBillingPlan server-side
  final String playMonthlyBasePlanId; // e.g. "pro-monthly"
  final String playYearlyBasePlanId; // e.g. "pro-yearly"

  const _Tier({
    required this.tier,
    required this.label,
    required this.storage,
    required this.monthlyPrice,
    required this.yearlyPrice,
    required this.playProductId,
    required this.playMonthlyBasePlanId,
    required this.playYearlyBasePlanId,
    this.premium = false,
  });

  String basePlanIdFor(String interval) =>
      interval == "yearly" ? playYearlyBasePlanId : playMonthlyBasePlanId;
}

/// Static pricing copy mirroring what's actually configured server-side in
/// RazorpayPlan/PlayBillingPlan — if these ever drift apart, the respective
/// endpoints already return a clean "not configured yet" error rather than
/// crashing. Yearly is exactly 10x monthly for both tiers — i.e. 2 months free.
const _tiers = [
  _Tier(
    tier: "pro", label: "Pro", storage: "100GB", monthlyPrice: 199, yearlyPrice: 1990,
    playProductId: "silvora_pro", playMonthlyBasePlanId: "pro-monthly", playYearlyBasePlanId: "pro-yearly",
  ),
  _Tier(
    tier: "enterprise", label: "Enterprise", storage: "1TB", monthlyPrice: 599, yearlyPrice: 5990, premium: true,
    playProductId: "silvora_enterprise", playMonthlyBasePlanId: "enterprise-monthly", playYearlyBasePlanId: "enterprise-yearly",
  ),
];

class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> with WidgetsBindingObserver {
  Future<Map<String, dynamic>>? _quotaFuture;
  String _interval = "monthly"; // toggle shared by both tier cards
  String? _subscribingTier; // which card's button is mid-flight, for a per-card spinner
  String? _subscribingInterval;
  String? _subscribingMethod; // "web" | "play" -- which button on that card
  String? _error;
  bool _purchasePending = false; // distinct from _error -- UPI-based Play payments commonly stay pending a while

  bool _playAvailable = false;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  final InAppPurchase _iap = InAppPurchase.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _quotaFuture = ApiService.getQuota();
    _purchaseSubscription = _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onError: (_) {
        // The stream itself erroring (not an individual purchase failing,
        // see PurchaseStatus.error for that) is rare and not actionable
        // here -- the per-purchase status handling below covers real
        // failures. Nothing to surface for a stream-level hiccup.
      },
    );
    _iap.isAvailable().then((available) {
      if (mounted) setState(() => _playAvailable = available);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _purchaseSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Subscribing via the website happens in the external browser, not
    // in-app. Re-fetch quota on resume so this screen picks up the real,
    // server-confirmed tier once the user comes back — the webhook that
    // actually flips the tier runs independently of this app either way.
    // A Play purchase completing is instead caught by _onPurchaseUpdate
    // directly, it doesn't need this resume hook.
    if (state == AppLifecycleState.resumed && _subscribingMethod == "web" && _subscribingTier != null) {
      setState(() {
        _quotaFuture = ApiService.getQuota();
        _subscribingTier = null;
        _subscribingInterval = null;
        _subscribingMethod = null;
      });
    }
  }

  Future<void> _subscribeViaWeb(_Tier tier) async {
    setState(() {
      _error = null;
      _subscribingTier = tier.tier;
      _subscribingInterval = _interval;
      _subscribingMethod = "web";
    });

    try {
      final url = await ApiService.getBillingWebLink(tier.tier, _interval);
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      // Deliberately not resetting state here — didChangeAppLifecycleState
      // handles that once the user comes back from the browser.
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst("Exception: ", "");
        _subscribingTier = null;
        _subscribingInterval = null;
        _subscribingMethod = null;
      });
    }
  }

  Future<void> _subscribeViaPlay(_Tier tier) async {
    setState(() {
      _error = null;
      _subscribingTier = tier.tier;
      _subscribingInterval = _interval;
      _subscribingMethod = "play";
    });

    try {
      final obfuscatedAccountId = await ApiService.getPlayObfuscatedAccountId();

      // queryProductDetails returns one GooglePlayProductDetails entry PER
      // OFFER under this product id (each entry already points at a single
      // subscriptionOfferDetails index and resolves its own .offerToken),
      // not one entry containing a list to pick from -- so the base plan
      // this tier/interval needs is selected by filtering the response
      // list, not by digging into a single entry's offer list.
      final response = await _iap.queryProductDetails({tier.playProductId});
      if (response.error != null || response.productDetails.isEmpty) {
        throw Exception("This plan isn't available on Google Play right now.");
      }

      final targetBasePlanId = tier.basePlanIdFor(_interval);
      final match = response.productDetails.cast<GooglePlayProductDetails>().firstWhere(
        (details) {
          final idx = details.subscriptionIndex;
          if (idx == null) return false;
          final offers = details.productDetails.subscriptionOfferDetails;
          if (offers == null || idx >= offers.length) return false;
          return offers[idx].basePlanId == targetBasePlanId;
        },
        orElse: () => throw Exception("This plan's $_interval option isn't set up yet."),
      );

      final purchaseParam = GooglePlayPurchaseParam(
        productDetails: match,
        applicationUserName: obfuscatedAccountId,
        offerToken: match.offerToken,
      );

      // Subscriptions go through buyNonConsumable -- the plugin has no
      // separate "buy subscription" call, the product type is determined
      // by what's configured in Play Console, not by which method is called.
      await _iap.buyNonConsumable(purchaseParam: purchaseParam);
      // Resolution (success/pending/error) arrives via _onPurchaseUpdate,
      // not as a return value here.
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst("Exception: ", "");
        _subscribingTier = null;
        _subscribingInterval = null;
        _subscribingMethod = null;
      });
    }
  }

  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.pending) {
        if (!mounted) return;
        setState(() {
          _error = null; // pending isn't an error
          _purchasePending = true;
        });
        continue;
      }

      if (purchase.status == PurchaseStatus.error) {
        if (!mounted) return;
        setState(() {
          _error = purchase.error?.message ?? "The purchase didn't go through.";
          _purchasePending = false;
          _subscribingTier = null;
          _subscribingInterval = null;
          _subscribingMethod = null;
        });
        continue;
      }

      if (purchase.status == PurchaseStatus.purchased || purchase.status == PurchaseStatus.restored) {
        try {
          await ApiService.verifyPlayPurchase(
            purchaseToken: purchase.verificationData.serverVerificationData,
            productId: purchase.productID,
          );
          // Only complete the purchase (clears it from the plugin's local
          // pending queue) once the backend has actually verified and
          // granted it. If verify fails below, this is deliberately left
          // uncompleted, so the plugin redelivers it via purchaseStream on
          // next app start/restorePurchases() -- a free retry path.
          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }
          if (!mounted) return;
          setState(() {
            _quotaFuture = ApiService.getQuota();
            _purchasePending = false;
            _subscribingTier = null;
            _subscribingInterval = null;
            _subscribingMethod = null;
          });
        } catch (e) {
          if (!mounted) return;
          setState(() {
            _error = e.toString().replaceFirst("Exception: ", "");
            _purchasePending = false;
            _subscribingTier = null;
            _subscribingInterval = null;
            _subscribingMethod = null;
          });
        }
      }
    }
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
            if (_purchasePending) ...[
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: SilvoraColors.gold.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: SilvoraColors.gold.withValues(alpha: 0.4)),
                ),
                child: const Row(
                  children: [
                    SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: SilvoraColors.gold),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Waiting for your payment to confirm — this can take a little longer for UPI, no need to retry.",
                        style: TextStyle(color: SilvoraColors.gold, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
    final isSubscribingThisCard = _subscribingTier == tier.tier && _subscribingInterval == _interval;
    final isSubscribingViaPlay = isSubscribingThisCard && _subscribingMethod == "play";
    final isSubscribingViaWeb = isSubscribingThisCard && _subscribingMethod == "web";
    final anyInFlight = _subscribingTier != null;
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
          if (_playAvailable) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: tier.premium
                    ? ElevatedButton.styleFrom(backgroundColor: SilvoraColors.gold, foregroundColor: const Color(0xFF1A1408))
                    : null,
                onPressed: anyInFlight ? null : () => _subscribeViaPlay(tier),
                child: isSubscribingViaPlay
                    ? const SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text("Pay with Google Play"),
              ),
            ),
            const SizedBox(height: 8),
          ],
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: anyInFlight ? null : () => _subscribeViaWeb(tier),
              child: isSubscribingViaWeb
                  ? SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: SilvoraColors.textSecondary),
                    )
                  : Text(_playAvailable ? "Pay via Website" : "Subscribe to ${tier.label}"),
            ),
          ),
          if (_playAvailable) ...[
            const SizedBox(height: 8),
            Text(
              // Required-disclosure wording -- pull the actual current text
              // from the Play Console Alternative Billing declaration at
              // setup time, this is a placeholder shape, not final copy.
              "Paying via the website uses a different checkout, outside Google Play.",
              style: TextStyle(color: SilvoraColors.textMuted, fontSize: 11),
            ),
          ],
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
