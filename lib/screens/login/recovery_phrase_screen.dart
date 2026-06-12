import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/silvora_theme.dart';
import 'login_screen.dart';

/// Shown once, right after a vault is created. The 24-word phrase is the only
/// way back in if the password is forgotten, so we make the user acknowledge
/// they've saved it before continuing.
class RecoveryPhraseScreen extends StatefulWidget {
  final String phrase;
  const RecoveryPhraseScreen({super.key, required this.phrase});

  @override
  State<RecoveryPhraseScreen> createState() => _RecoveryPhraseScreenState();
}

class _RecoveryPhraseScreenState extends State<RecoveryPhraseScreen> {
  bool _saved = false;

  @override
  Widget build(BuildContext context) {
    final words = widget.phrase.split(' ');

    return Scaffold(
      backgroundColor: SilvoraColors.bg,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text("Recovery Phrase",
            style: GoogleFonts.syne(fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: SilvoraColors.warn.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: SilvoraColors.warn.withValues(alpha: 0.4)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: SilvoraColors.warn, size: 22),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Write these 24 words down and keep them safe. If you forget "
                        "your password, this is the ONLY way back into your vault. "
                        "We can't recover them for you.",
                        style: TextStyle(color: SilvoraColors.textSecondary, fontSize: 12.5, height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: SilvoraColors.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: SilvoraColors.border),
                  ),
                  child: GridView.builder(
                    itemCount: words.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 4.2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 6,
                    ),
                    itemBuilder: (context, i) => Row(
                      children: [
                        SizedBox(
                          width: 26,
                          child: Text("${i + 1}",
                              style: const TextStyle(color: SilvoraColors.textMuted, fontSize: 12)),
                        ),
                        Text(
                          words[i],
                          style: const TextStyle(
                            color: SilvoraColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: widget.phrase));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Copied. Store it somewhere safe, then clear your clipboard.")),
                  );
                },
                icon: const Icon(Icons.copy_rounded, size: 18, color: SilvoraColors.primaryLight),
                label: const Text("Copy phrase", style: TextStyle(color: SilvoraColors.primaryLight)),
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                value: _saved,
                onChanged: (v) => setState(() => _saved = v ?? false),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: SilvoraColors.primary,
                title: const Text(
                  "I have written down my recovery phrase",
                  style: TextStyle(color: SilvoraColors.textSecondary, fontSize: 13.5),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saved
                      ? () => Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                            (route) => false,
                          )
                      : null,
                  child: const Text("Continue to sign in"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
