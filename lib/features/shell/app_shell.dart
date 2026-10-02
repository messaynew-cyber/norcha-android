// Norcha Print — the shell.
//
// FIVE PAGES behind one nav bar:
//
//   Home   ፩  the studio, prices at a glance, the next deadline
//   Quote  ፪  build a job and get a number
//   Order  ፫  "did my photos arrive?" (live API)
//   Upload ፬  send photos (live API)
//   Studio ፭  where the shop is, hours, how to reach a human
//
// WHY IndexedStack
// Each tab keeps its state. Coming back to a half-built quote and finding it
// reset is the single most infuriating thing a small app can do, and the fix is
// one widget deep.

import 'package:flutter/material.dart';

import '../../core/lang.dart';
import '../../theme/app_theme.dart';
import '../../theme/theme_controller.dart';
import '../../widgets/lang_toggle.dart';
import '../../widgets/theme_toggle.dart';

/// Tab indices, named so no screen has to remember a magic number.
class NorchaTab {
  static const home = 0;
  static const quote = 1;
  static const order = 2;
  static const upload = 3;
  static const studio = 4;
}

class AppShell extends StatefulWidget {
  final int initialIndex;
  final List<Widget> pages;
  final ThemeController themes;
  final LangController langs;

  const AppShell({
    super.key,
    this.initialIndex = 0,
    required this.pages,
    required this.themes,
    required this.langs,
  });

  /// Switch tabs from anywhere inside the shell without threading a callback
  /// through every constructor on the way down. Returns null outside a shell
  /// (a page rendered standalone in a test), which callers must tolerate.
  static NorchaShellController? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<NorchaShellScope>()?.controller;

  @override
  State<AppShell> createState() => _AppShellState();
}

abstract class NorchaShellController {
  void selectTab(int index);
  ThemeController get themes;
  LangController get langs;
}

class NorchaShellScope extends InheritedWidget {
  final NorchaShellController controller;
  const NorchaShellScope({
    super.key,
    required this.controller,
    required super.child,
  });

  @override
  bool updateShouldNotify(NorchaShellScope old) => false;
}

class _AppShellState extends State<AppShell> implements NorchaShellController {
  late int _index = widget.initialIndex;

  @override
  ThemeController get themes => widget.themes;

  @override
  LangController get langs => widget.langs;

  @override
  void selectTab(int index) {
    if (index < 0 || index >= _tabs.length || index == _index) return;
    setState(() => _index = index);
  }

  static const _tabs = <_TabSpec>[
    _TabSpec('nav.home', '\u1369', Icons.home_outlined, Icons.home_rounded),
    _TabSpec('nav.quote', '\u136A', Icons.calculate_outlined,
        Icons.calculate_rounded),
    _TabSpec('nav.order', '\u136B', Icons.search_outlined, Icons.search_rounded),
    _TabSpec('nav.upload', '\u136C', Icons.add_photo_alternate_outlined,
        Icons.add_photo_alternate_rounded),
    _TabSpec('nav.studio', '\u136D', Icons.storefront_outlined,
        Icons.storefront_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final c = NorchaColors.of(context);

    // Exit intent: a slow cross-fade of the whole body when the theme switches,
    // so the flip reads as the light changing rather than the app being redrawn.
    return Scaffold(
      backgroundColor: c.ground,
      body: NorchaShellScope(
        controller: this,
        child: AnimatedSwitcher(
          duration: Motion.medium,
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: KeyedSubtree(
            key: ValueKey(widget.themes.mode),
            child: IndexedStack(index: _index, children: widget.pages),
          ),
        ),
      ),
      bottomNavigationBar: _ClothNavBar(
        index: _index,
        tabs: _tabs,
        onSelect: selectTab,
        lang: widget.langs.lang,
      ),
    );
  }
}

class _TabSpec {
  final String label;   // a LangController key
  final String numeral; // the Ge'ez chapter mark
  final IconData icon;
  final IconData activeIcon;
  const _TabSpec(this.label, this.numeral, this.icon, this.activeIcon);
}

/// The bottom bar, built rather than borrowed.
///
/// Material's NavigationBar puts a pill indicator behind the selected tab —
/// exactly the generic chrome this app is trying not to have. Here the selected
/// tab gets a gold tibeb tick AND its Ge'ez numeral, so the navigation carries
/// the same chapter system as the pages themselves.
class _ClothNavBar extends StatelessWidget {
  final int index;
  final List<_TabSpec> tabs;
  final ValueChanged<int> onSelect;
  final NorchaLang lang;

  const _ClothNavBar({
    required this.index,
    required this.tabs,
    required this.onSelect,
    required this.lang,
  });

  @override
  Widget build(BuildContext context) {
    final c = NorchaColors.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.card,
        border: Border(top: BorderSide(color: c.line, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              for (var i = 0; i < tabs.length; i++)
                Expanded(
                  child: _NavItem(
                    spec: tabs[i],
                    selected: i == index,
                    lang: lang,
                    onTap: () => onSelect(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final _TabSpec spec;
  final bool selected;
  final NorchaLang lang;
  final VoidCallback onTap;

  const _NavItem({
    required this.spec,
    required this.selected,
    required this.lang,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = NorchaColors.of(context);
    final colour = selected ? Brand.action(c) : c.inkFaint;

    return InkWell(
      onTap: onTap,
      splashColor: Brand.action(c).withOpacity(0.06),
      highlightColor: Colors.transparent,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: Motion.fast,
            curve: Curves.easeOut,
            width: selected ? 18 : 0,
            height: 2,
            margin: const EdgeInsets.only(bottom: 5),
            decoration: BoxDecoration(
              color: Brand.gold,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          // The numeral sits behind the icon as a tiny chapter mark. It is what
          // makes the nav feel like part of this app rather than part of
          // Material.
          Stack(
            alignment: Alignment.center,
            children: [
              if (selected)
                Text(
                  spec.numeral,
                  style: TextStyle(
                    fontFamily: NorchaTypeFace.amharic,
                    fontSize: 30,
                    height: 1.0,
                    color: Brand.gold.withOpacity(0.16),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              AnimatedScale(
                duration: Motion.fast,
                scale: selected ? 1.06 : 1.0,
                child: Icon(
                  selected ? spec.activeIcon : spec.icon,
                  size: 21,
                  color: colour,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          // The nav label follows the app language. At 10.5px the Amharic is
          // set in the Ethiopic face so it does not fall back to a Latin font
          // and render as boxes.
          Text(
            L.t(spec.label, lang),
            style: NorchaType.bodySmall(c).copyWith(
              fontFamily: lang.isAmharic
                  ? NorchaTypeFace.amharic
                  : NorchaTypeFace.body,
              fontSize: lang.isAmharic ? 11 : 10.5,
              letterSpacing: lang.isAmharic ? 0 : 0.3,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: colour,
            ),
          ),
        ],
      ),
    );
  }
}

/// The header controls: language and appearance, side by side.
///
/// One widget so every page's header is identical. Two separate trailing slots
/// would drift — one page with the language first, another with the theme, and
/// the controls become something you have to hunt for.
class HeaderControls extends StatelessWidget {
  final ThemeController themes;
  final LangController langs;

  const HeaderControls({
    super.key,
    required this.themes,
    required this.langs,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        LangToggle(controller: langs),
        const SizedBox(width: 8),
        ThemeToggle(controller: themes),
      ],
    );
  }
}

/// Kept so existing call sites do not break — a header with only the theme.
class ThemeButton extends StatelessWidget {
  final ThemeController themes;
  const ThemeButton({super.key, required this.themes});

  @override
  Widget build(BuildContext context) => ThemeToggle(controller: themes);
}
