import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/silvora_theme.dart';
import 'login_screen.dart';

/// Shown once, right after a vault is created. The 24-word phrase is the only
/// way back in if the password is forgotten, so before letting the user
/// leave this screen we make them prove they actually recorded it — a
/// checkbox alone doesn't stop someone from tapping through without saving
/// anything, and for a zero-knowledge vault that means permanent, silent
/// data loss with no support-ticket recovery path.
class RecoveryPhraseScreen extends StatefulWidget {
  final String phrase;
  const RecoveryPhraseScreen({super.key, required this.phrase});

  @override
  State<RecoveryPhraseScreen> createState() => _RecoveryPhraseScreenState();
}

class _RecoveryPhraseScreenState extends State<RecoveryPhraseScreen> {
  bool _saved = false;
  bool _verifying = false;
  Timer? _clipboardClearTimer;

  @override
  void dispose() {
    _clipboardClearTimer?.cancel();
    super.dispose();
  }

  void _copyPhrase() {
    Clipboard.setData(ClipboardData(text: widget.phrase));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Copied. It will be cleared from your clipboard in 60 seconds."),
      ),
    );

    // The phrase sitting in the system clipboard is readable by any other
    // app with clipboard access. Clear it automatically rather than relying
    // on the user to remember to do it themselves.
    _clipboardClearTimer?.cancel();
    _clipboardClearTimer = Timer(const Duration(seconds: 60), () async {
      final current = await Clipboard.getData(Clipboard.kTextPlain);
      // Only wipe it if it's still OUR phrase — the user may have already
      // copied something else in the meantime, and we shouldn't clobber that.
      if (current?.text == widget.phrase) {
        await Clipboard.setData(const ClipboardData(text: ""));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final words = widget.phrase.split(' ');

    return Scaffold(
      backgroundColor: SilvoraColors.bg,
      appBar: AppBar(
        automaticallyImplyLeading: _verifying,
        title: Text(_verifying ? "Confirm Your Phrase" : "Recovery Phrase",
            style: GoogleFonts.syne(fontWeight: FontWeight.w700)),
        leading: _verifying
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _verifying = false),
              )
            : null,
      ),
      body: SafeArea(
        child: _verifying
            ? _VerifyStep(
                words: words,
                onVerified: () => Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                ),
              )
            : _ShowStep(
                words: words,
                saved: _saved,
                onSavedChanged: (v) => setState(() => _saved = v),
                onCopy: _copyPhrase,
                onContinue: () => setState(() => _verifying = true),
              ),
      ),
    );
  }
}

class _ShowStep extends StatelessWidget {
  final List<String> words;
  final bool saved;
  final ValueChanged<bool> onSavedChanged;
  final VoidCallback onCopy;
  final VoidCallback onContinue;

  const _ShowStep({
    required this.words,
    required this.saved,
    required this.onSavedChanged,
    required this.onCopy,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
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
            onPressed: onCopy,
            icon: const Icon(Icons.copy_rounded, size: 18, color: SilvoraColors.primaryLight),
            label: const Text("Copy phrase", style: TextStyle(color: SilvoraColors.primaryLight)),
          ),
          const SizedBox(height: 8),
          CheckboxListTile(
            value: saved,
            onChanged: (v) => onSavedChanged(v ?? false),
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
              onPressed: saved ? onContinue : null,
              child: const Text("Verify and continue"),
            ),
          ),
        ],
      ),
    );
  }
}

/// Forces the user to prove they actually recorded the phrase by picking the
/// correct word for 3 random positions, each from a multiple-choice set of
/// 4 (the real word plus 3 decoys drawn from elsewhere in their own phrase —
/// avoids bundling a full BIP39 wordlist just for plausible-looking
/// distractors). All 3 must be answered correctly in one pass; any mistake
/// sends the user back to re-read the phrase rather than silently retrying,
/// since the whole point is to catch someone who never actually wrote it down.
class _VerifyStep extends StatefulWidget {
  final List<String> words;
  final VoidCallback onVerified;

  const _VerifyStep({required this.words, required this.onVerified});

  @override
  State<_VerifyStep> createState() => _VerifyStepState();
}

class _VerifyStepState extends State<_VerifyStep> {
  late final List<int> _positions;
  late final List<List<String>> _options;
  final Map<int, String> _selected = {};
  String? _error;

  @override
  void initState() {
    super.initState();
    final rng = Random.secure();

    // 3 distinct random positions out of the phrase.
    final indices = List.generate(widget.words.length, (i) => i)..shuffle(rng);
    _positions = indices.take(3).toList()..sort();

    _options = _positions.map((pos) {
      final correct = widget.words[pos];
      final decoyPool = List<String>.from(widget.words)..remove(correct);
      decoyPool.shuffle(rng);
      final choices = [correct, ...decoyPool.take(3)];
      choices.shuffle(rng);
      return choices;
    }).toList();
  }

  void _submit() {
    for (final pos in _positions) {
      if (_selected[pos] != widget.words[pos]) {
        setState(() {
          _error = "That's not right. Go back, re-read the phrase carefully, and try again.";
          _selected.clear();
        });
        return;
      }
    }
    widget.onVerified();
  }

  @override
  Widget build(BuildContext context) {
    final allAnswered = _positions.every((p) => _selected.containsKey(p));

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Select the correct word for each position below to confirm you've saved your phrase.",
            style: TextStyle(color: SilvoraColors.textSecondary, fontSize: 13.5, height: 1.4),
          ),
          const SizedBox(height: 20),
          if (_error != null)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: SilvoraColors.error.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: SilvoraColors.error.withValues(alpha: 0.4)),
              ),
              child: Text(_error!,
                  style: const TextStyle(color: SilvoraColors.error, fontSize: 13)),
            ),
          Expanded(
            child: ListView.separated(
              itemCount: _positions.length,
              separatorBuilder: (_, _) => const SizedBox(height: 20),
              itemBuilder: (context, i) {
                final pos = _positions[i];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Word #${pos + 1}",
                        style: const TextStyle(
                            color: SilvoraColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _options[i].map((word) {
                        final isSelected = _selected[pos] == word;
                        return ChoiceChip(
                          label: Text(word),
                          selected: isSelected,
                          onSelected: (_) => setState(() {
                            _selected[pos] = word;
                            _error = null;
                          }),
                          selectedColor: SilvoraColors.primary.withValues(alpha: 0.25),
                          backgroundColor: SilvoraColors.card,
                          labelStyle: TextStyle(
                            color: isSelected ? SilvoraColors.primaryLight : SilvoraColors.textSecondary,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          ),
                          side: BorderSide(
                            color: isSelected ? SilvoraColors.primaryLight : SilvoraColors.border,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                );
              },
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: allAnswered ? _submit : null,
              child: const Text("Confirm"),
            ),
          ),
        ],
      ),
    );
  }
}
