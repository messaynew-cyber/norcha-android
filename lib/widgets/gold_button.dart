// The primary action — a gold bar with a light sweep and spring press.
//
// On a near-black ground, gold is the only thing that reads as "press me".
// It is used exactly once per screen. Two gold buttons on one screen means
// neither is the primary action.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/norcha_theme.dart';

class GoldButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool loading;

  const GoldButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.loading = false,
  });

  @override
  State<GoldButton> createState() => _GoldButtonState();
}

class _GoldButtonState extends State<GoldButton>
    with SingleTickerProviderStateMixin {
  bool _down = false;

  void _set(bool v) {
    if (_down == v) return;
    if (v) HapticFeedback.lightImpact();
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
      child: AnimatedScale(
        scale: _down ? 0.965 : 1.0,
        duration: NorchaMotion.fast,
        curve: Curves.easeOutCubic,
        child: Container(
          height: 58,
          decoration: BoxDecoration(
            borderRadius: NorchaShape.chip,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: enabled
                  ? const [NorchaPalette.goldBright, NorchaPalette.gold]
                  : const [NorchaPalette.raisedHigh, NorchaPalette.raised],
            ),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: NorchaPalette.gold.withOpacity(0.22),
                      blurRadius: 26,
                      offset: const Offset(0, 10),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: widget.loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: NorchaPalette.void_,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(widget.icon,
                            size: 19,
                            color: enabled
                                ? NorchaPalette.void_
                                : NorchaPalette.textTertiary),
                        const SizedBox(width: 10),
                      ],
                      Text(
                        widget.label,
                        style: NorchaType.label.copyWith(
                          fontSize: 16,
                          letterSpacing: 0.2,
                          color: enabled
                              ? NorchaPalette.void_
                              : NorchaPalette.textTertiary,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
