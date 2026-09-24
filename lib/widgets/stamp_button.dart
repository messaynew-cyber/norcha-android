// The action — a pressed stamp, not a glowing bar.
//
// On the dark version the primary action was a gold bar with a light bleed,
// because on near-black only a lit surface reads as pressable.
//
// On paper the logic inverts. Ink is the action. A rust-coloured block, square
// corners, a hard offset shadow, and on press it *moves down into the page* —
// like a stamp coming down. The physical metaphor does the work that glow did.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/norcha_theme.dart';

class StampButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool loading;

  const StampButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.loading = false,
  });

  @override
  State<StampButton> createState() => _StampButtonState();
}

class _StampButtonState extends State<StampButton> {
  bool _down = false;

  void _set(bool v) {
    if (_down == v) return;
    if (v) HapticFeedback.mediumImpact();
    setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.loading;
    return GestureDetector(
      onTapDown: enabled ? (_) => _set(true) : null,
      onTapUp: enabled ? (_) => _set(false) : null,
      onTapCancel: enabled ? () => _set(false) : null,
      onTap: enabled ? widget.onPressed : null,
      child: AnimatedContainer(
        duration: PaperMotion.fast,
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, _down ? 3 : 0, 0),
        height: 56,
        decoration: BoxDecoration(
          color: enabled ? PaperPalette.rust : PaperPalette.kraftDeep,
          borderRadius: PaperShape.card,
          boxShadow: _down || !enabled
              ? null
              : const [
                  BoxShadow(
                    color: Color(0x2E000000),
                    blurRadius: 0,
                    offset: Offset(0, 3),
                  ),
                ],
        ),
        child: Center(
          child: widget.loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: PaperPalette.sheet,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(widget.icon,
                          size: 19,
                          color: enabled
                              ? PaperPalette.sheet
                              : PaperPalette.inkFaint),
                      const SizedBox(width: 10),
                    ],
                    Text(
                      widget.label,
                      style: PaperType.label.copyWith(
                        fontSize: 15.5,
                        letterSpacing: 0.3,
                        color: enabled
                            ? PaperPalette.sheet
                            : PaperPalette.inkFaint,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
