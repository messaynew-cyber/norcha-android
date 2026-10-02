// Norcha Print — the emphasis budget.
//
// SPEC: docs/DESIGN-LUXURY.md §5
//
// M3 Expressive's real contribution is spring physics plus SELECTIVE overshoot.
// The failure mode is applying it to everything, at which point nothing feels
// special because everything does. That is what this file prevents.
//
// The budget is deliberately small and enforced at runtime in debug: at most
// TWO expressive moments per screen. If a third is requested, it degrades to
// standard motion and logs a warning rather than throwing — a design rule should
// fail loudly in development and never break the app in a customer's hand.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme/norcha_theme.dart';

/// How much emphasis a movement is allowed to carry.
enum Emphasis {
  /// Routine movement — list items, chips, tabs. No overshoot. Reusable freely.
  routine,

  /// A moment worth noticing — quantity change, selection landing, sheet
  /// opening. Overshoot. Budgeted.
  expressive,

  /// Tap feedback. Must complete under 80ms or it reads as lag.
  press,
}

class MotionBudget {
  MotionBudget._();

  /// At most this many [Emphasis.expressive] movements per screen. Two is
  /// enough for the two things that actually sell: the number changing and the
  /// sheet arriving.
  static const int perScreen = 2;

  static final Set<String> _claimed = <String>{};

  /// Claim one expressive slot. Returns false when the budget is spent, and the
  /// caller should fall back to routine motion.
  @visibleForTesting
  static bool claim(String screenId, String reason) {
    final key = '$screenId::$reason';
    if (_claimed.contains(key)) return true;
    if (_claimed.where((k) => k.startsWith('$screenId::')).length >= perScreen) {
      if (kDebugMode) {
        debugPrint(
          'MotionBudget: "$reason" on $screenId degraded to routine — '
          'budget of $perScreen already spent. See docs/DESIGN-LUXURY.md §5.',
        );
      }
      return false;
    }
    _claimed.add(key);
    return true;
  }

  /// Call from dispose so a revisited screen gets its budget back.
  static void release(String screenId) {
    _claimed.removeWhere((k) => k.startsWith('$screenId::'));
  }
}

/// Resolves an [Emphasis] to a concrete animation. Screens ask for emphasis and
/// get back the right physics without hand-picking springs, which is how motion
/// stays consistent across a codebase.
class Motion {
  static Duration durationOf(Emphasis e) {
    switch (e) {
      case Emphasis.press:
        // Under 80ms. Slower reads as lag, and lag reads as cheap.
        return const Duration(milliseconds: 70);
      case Emphasis.expressive:
        return NorchaMotion.medium;
      case Emphasis.routine:
        return NorchaMotion.fast;
    }
  }

  static Curve curveOf(Emphasis e) {
    switch (e) {
      case Emphasis.press:
        return Curves.easeOut;
      case Emphasis.expressive:
        // A little overshoot: arrives with life rather than stopping dead.
        return Curves.easeOutBack;
      case Emphasis.routine:
        // No overshoot. Routine movement should not draw attention.
        return Curves.easeOutCubic;
    }
  }
}

/// Scale response for pressable things. The whole point is that it is FELT
/// rather than seen — 0.97 is enough, and anything more looks like a bounce
/// house.
class Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scale;

  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.scale = 0.97,
  });

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap == null ? null : (_) => setState(() => _down = true),
      onTapUp: widget.onTap == null ? null : (_) => setState(() => _down = false),
      onTapCancel: widget.onTap == null ? null : () => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? widget.scale : 1.0,
        duration: Motion.durationOf(Emphasis.press),
        curve: Motion.curveOf(Emphasis.press),
        child: widget.child,
      ),
    );
  }
}

/// Staggered entrance for a list of items.
///
/// Implemented locally rather than pulled from a package for one reason: the
/// `AnimateList` replay bug. If the whole list is rebuilt on every state change,
/// old rows replay their entrance and a simple refresh reads as broken. Here the
/// animation is keyed and runs ONCE per item — cheap, and it cannot replay.
class StaggeredReveal extends StatefulWidget {
  final int index;
  final Widget child;
  final Duration step;
  final Duration of;

  const StaggeredReveal({
    super.key,
    required this.index,
    required this.child,
    this.step = const Duration(milliseconds: 55),
    this.of = const Duration(milliseconds: 380),
  });

  @override
  State<StaggeredReveal> createState() => _StaggeredRevealState();
}

class _StaggeredRevealState extends State<StaggeredReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: widget.of);
    final curve = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
    _fade = curve;
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(curve);

    // Capped so a 40-item list does not take two seconds to finish revealing.
    final delayMs = (widget.index * widget.step.inMilliseconds).clamp(0, 600);
    Future<void>.delayed(Duration(milliseconds: delayMs), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}
