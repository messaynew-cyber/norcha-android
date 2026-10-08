// Norcha Print — the animated page scaffold.
//
// Every page in this app is: a Ge'ez ghost numeral behind, a header with the
// selvedge, and content that arrives rather than appears.
//
// WHY A SCAFFOLD AND NOT PER-PAGE CODE
// The first pass at this had StaggeredReveal wired into exactly one list, which
// is why the app felt static. Motion that lives in five different pages will be
// forgotten in four of them. Funnelling the entry animation, the parallax and
// the watermark through one widget means a new page is animated by default and
// a developer has to actively opt OUT to make it static.

import 'package:flutter/material.dart';

import '../core/lang.dart';
import '../theme/app_theme.dart';
import '../theme/ghost_numerals.dart';
import 'ethiopian.dart';

class PageScaffold extends StatefulWidget {
  final int chapter;              // 1-based — drives the ghost numeral
  final String eyebrowKey;        // LangController key
  final String titleKey;          // LangController key
  final Widget? trailing;
  /// Optional woven band above the content. Used on Home and Studio — the two
  /// pages that are about the shop rather than about a transaction.
  final bool telafi;

  /// Content. Wrapped in a staggered reveal internally.
  final List<Widget> children;

  /// Optional pinned bar (the quote page's total). Excluded from the scroll.
  final Widget? bottomBar;

  final GhostStyle ghostStyle;
  final bool ghostLeft;

  const PageScaffold({
    super.key,
    required this.chapter,
    required this.eyebrowKey,
    required this.titleKey,
    required this.children,
    this.trailing,
    this.bottomBar,
    this.ghostStyle = GhostStyle.soft,
    this.ghostLeft = false,
    this.telafi = false,
  });

  @override
  State<PageScaffold> createState() => _PageScaffoldState();
}

class _PageScaffoldState extends State<PageScaffold> {
  final _scroll = ScrollController();
  double _offset = 0;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      // Only rebuild when the change is visible. A listener that setStates on
      // every scroll frame is the classic way to make a Flutter list stutter.
      final o = _scroll.offset;
      if ((o - _offset).abs() > 1.5) {
        setState(() => _offset = o);
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = NorchaColors.of(context);

    // The header collapses as you scroll: the eyebrow fades, the big serif
    // title shrinks and drifts up. This is the single strongest cue that a
    // screen is alive rather than a static layout that happens to move.
    final collapse = (_offset / 130).clamp(0.0, 1.0);
    final titleSize = 38 - (10 * collapse);
    final titleOpacity = 1.0 - (0.35 * collapse);

    return DecoratedBox(
      decoration: BoxDecoration(color: c.ground),
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // The watermark. Positioned, parallaxed at a fraction of scroll so
            // it reads as being behind the content rather than part of it.
            Positioned(
              top: -_offset * 0.14,
              left: 0,
              right: 0,
              child: SizedBox(
                height: 320,
                child: Stack(
                  children: [
                    GhostNumeral(
                      numeral: GeezNumeral.at(widget.chapter),
                      style: widget.ghostStyle,
                      left: widget.ghostLeft,
                      size: 250,
                    ),
                  ],
                ),
              ),
            ),

            Column(
              children: [
                Expanded(
                  child: ListView(
                    controller: _scroll,
                    padding: const EdgeInsets.only(bottom: 28),
                    children: [
                      _Header(
                        eyebrowKey: widget.eyebrowKey,
                        titleKey: widget.titleKey,
                        trailing: widget.trailing,
                        size: titleSize,
                        opacity: titleOpacity,
                        collapse: collapse,
                        telafi: widget.telafi,
                      ),
                      ...widget.children.asMap().entries.map(
                        (e) => StaggeredReveal(
                          index: e.key,
                          child: e.value,
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.bottomBar != null) widget.bottomBar!,
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String eyebrowKey;
  final String titleKey;
  final Widget? trailing;
  final double size;
  final double opacity;
  final double collapse;
  final bool telafi;

  const _Header({
    required this.eyebrowKey,
    required this.titleKey,
    this.trailing,
    required this.size,
    required this.opacity,
    required this.collapse,
    required this.telafi,
  });

  @override
  Widget build(BuildContext context) {
    final c = NorchaColors.of(context);
    final lang = LangController.of(context).lang;

    // In Amharic the TITLE is Amharic and the subtitle is English; in English
    // the reverse. The secondary line is never hidden — it is what makes the
    // app usable by whoever happens to be holding the phone, which at a counter
    // is often not the person who set it up.
    final primary = L.t(titleKey, lang);
    final secondary = L.t(titleKey, lang == NorchaLang.am
        ? NorchaLang.en
        : NorchaLang.am);

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 18 - (6 * collapse), 24, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The selvedge: three dyed threads at the very top of the page.
          // DESIGN.md allows it here and above the footer, nowhere else.
          Opacity(
            opacity: 1 - (0.6 * collapse),
            child: const Selvedge(),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Text(
                  // `.toUpperCase()` is a no-op on Ethiopic — Amharic has no
                  // case. Harmless, and clearer than branching for it.
                  L.t(eyebrowKey, lang).toUpperCase(),
                  style: NorchaType.sectionLabel(c, amharic: lang.isAmharic)
                      .copyWith(letterSpacing: lang.isAmharic ? 1.2 : 2.4)),
              const Spacer(),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 10),
          const TibebRule(),
          const SizedBox(height: 12),
          AnimatedOpacity(
            duration: Motion.fast,
            opacity: opacity,
            child: AnimatedDefaultTextStyle(
              duration: Motion.fast,
              style: NorchaType.display(c).copyWith(
                fontFamily: lang.isAmharic
                    ? NorchaTypeFace.amharic
                    : NorchaTypeFace.display,
                fontSize: size,
              ),
              child: Text(primary),
            ),
          ),
          if (secondary.isNotEmpty && secondary != primary) ...[
            const SizedBox(height: 5),
            Text(
              secondary,
              style: (lang.isAmharic
                      ? NorchaType.bodySmall(c)
                      : NorchaType.amharicText(c))
                  .copyWith(fontSize: 15, color: c.inkSoft),
            ),
          ],
        ],
      ),
    );
  }
}

/// Staggered entrance for list content.
///
/// Implemented locally rather than pulled from a package for one reason: the
/// AnimateList replay bug. If the whole list rebuilds on every state change,
/// old rows replay their entrance and a simple refresh reads as broken. Here
/// the animation is keyed and runs ONCE per item.
class StaggeredReveal extends StatefulWidget {
  final int index;
  final Widget child;
  final Duration step;
  final Duration of;
  final Offset from;

  const StaggeredReveal({
    super.key,
    required this.index,
    required this.child,
    this.step = const Duration(milliseconds: 55),
    this.of = const Duration(milliseconds: 420),
    this.from = const Offset(0, 0.05),
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
    _slide = Tween<Offset>(begin: widget.from, end: Offset.zero).animate(curve);

    // Capped so a 40-item list does not take two seconds to finish revealing.
    final delayMs = (widget.index * widget.step.inMilliseconds).clamp(0, 520);
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

/// Press feedback. A small scale-down plus a spring back — the cheapest way to
/// make a flat card feel like a physical object.
class Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scale;

  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.scale = 0.975,
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
        duration: Motion.press,
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
