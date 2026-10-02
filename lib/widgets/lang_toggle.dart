// Norcha Print — the language switch.
//
// BOTH SCRIPTS ARE SHOWN AT ONCE — "አማ / EN" — rather than a single label that
// changes. Two reasons:
//
//   1. A person who cannot read the current language cannot read the control
//      that switches it. Showing both means the switch is always legible to
//      whoever is holding the phone, which at a print counter is often not the
//      person who set the app up.
//   2. It is the honest representation of what the app is. Norcha is bilingual;
//      the control should look bilingual rather than look like a setting.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/lang.dart';
import '../theme/app_theme.dart';

class LangToggle extends StatelessWidget {
  final LangController controller;

  /// Compact: just the glyphs, for a page header. Full: with the word.
  final bool compact;

  const LangToggle({super.key, required this.controller, this.compact = true});

  @override
  Widget build(BuildContext context) {
    final c = NorchaColors.of(context);
    final am = controller.lang.isAmharic;

    return GestureDetector(
      onTap: () {
        controller.toggle();
        // Haptics can throw on hardware with no vibrator; a language switch
        // must not die because a motor is missing.
        try {
          HapticFeedback.selectionClick();
        } catch (_) {}
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: Motion.fast,
        curve: Curves.easeOut,
        height: 40,
        padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Corners.pill),
          border: Border.all(color: c.line),
          color: c.card,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Side(label: 'አማ', active: am, colour: c, amharic: true),
            // The divider is the whole control: it shows these are two states
            // of one thing, not two buttons.
            Container(
              width: 1,
              height: 16,
              margin: const EdgeInsets.symmetric(horizontal: 7),
              color: c.line,
            ),
            _Side(label: 'EN', active: !am, colour: c, amharic: false),
          ],
        ),
      ),
    );
  }
}

class _Side extends StatelessWidget {
  final String label;
  final bool active;
  final NorchaColors colour;
  final bool amharic;

  const _Side({
    required this.label,
    required this.active,
    required this.colour,
    required this.amharic,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedDefaultTextStyle(
      duration: Motion.fast,
      style: TextStyle(
        fontFamily: amharic ? NorchaTypeFace.amharic : NorchaTypeFace.body,
        fontSize: amharic ? 13 : 11.5,
        height: 1.2,
        letterSpacing: amharic ? 0 : 0.6,
        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
        color: active ? Brand.action(colour) : colour.inkFaint,
      ),
      child: Text(label),
    );
  }
}
