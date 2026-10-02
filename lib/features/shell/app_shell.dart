// Norcha Print — the shell.
//
// FIVE PAGES, and this is the widget that makes them a product rather than a
// demo:
//
//   Home    — the studio, prices at a glance, the next deadline
//   Quote   — build a job and get a number
//   Order   — "did my photos arrive?" (the live API)
//   Upload  — send photos (the live API)
//   Studio  — where the shop is, hours, how to reach a human
//
// WHY A SHELL WITH AN INDEX RATHER THAN ROUTES ALONE
// Bottom-tab navigation must preserve each tab's state — coming back to a
// half-built quote and finding it reset is the single most infuriating thing a
// small app can do. IndexedStack keeps all five alive.

import 'package:flutter/material.dart';

import '../../theme/netela.dart';
import '../../theme/norcha_theme.dart';

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

  const AppShell({super.key, this.initialIndex = 0, required this.pages});

  /// Switch tabs from anywhere inside the shell, without threading a callback
  /// through every constructor on the way down. Returns null outside a shell
  /// (a page rendered standalone in a test), which callers must tolerate.
  static NorchaShellController? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<NorchaShellScope>()?.controller;

  @override
  State<AppShell> createState() => _AppShellState();
}

/// The handle a page uses to move between tabs.
abstract class NorchaShellController {
  void selectTab(int index);
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
  void selectTab(int index) {
    if (index < 0 || index >= _tabs.length || index == _index) return;
    setState(() => _index = index);
  }

  static const _tabs = <_TabSpec>[
    _TabSpec('Home', Icons.home_outlined, Icons.home_rounded),
    _TabSpec('Quote', Icons.calculate_outlined, Icons.calculate_rounded),
    _TabSpec('Order', Icons.search_outlined, Icons.search_rounded),
    _TabSpec('Upload', Icons.add_photo_alternate_outlined,
        Icons.add_photo_alternate_rounded),
    _TabSpec('Studio', Icons.storefront_outlined, Icons.storefront_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NorchaPalette.paper,
      // IndexedStack: every tab stays alive, so a half-built quote survives a
      // trip to the Order tab. This is the whole reason for a shell.
      body: NorchaShellScope(
        controller: this,
        child: IndexedStack(index: _index, children: widget.pages),
      ),
      bottomNavigationBar: _ClothNavBar(
        index: _index,
        tabs: _tabs,
        onSelect: (i) {
          if (i == _index) return;
          setState(() => _index = i);
        },
      ),
    );
  }
}

class _TabSpec {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  const _TabSpec(this.label, this.icon, this.activeIcon);
}

/// The bottom bar, built rather than borrowed.
///
/// Material's NavigationBar would put a pill indicator behind the selected tab.
/// That pill is exactly the kind of generic Material chrome this app is trying
/// not to have. Instead the selected tab gets a gold tibeb tick above it:
/// quieter, and it belongs to this brand rather than to the framework.
class _ClothNavBar extends StatelessWidget {
  final int index;
  final List<_TabSpec> tabs;
  final ValueChanged<int> onSelect;

  const _ClothNavBar({
    required this.index,
    required this.tabs,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: NorchaPalette.card,
        border: Border(top: BorderSide(color: NorchaPalette.line, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: [
              for (var i = 0; i < tabs.length; i++)
                Expanded(
                  child: _NavItem(
                    spec: tabs[i],
                    selected: i == index,
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
  final VoidCallback onTap;

  const _NavItem({
    required this.spec,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colour = selected ? NorchaPalette.pine : NorchaPalette.inkFaint;

    return InkWell(
      onTap: onTap,
      splashColor: NorchaPalette.pine.withOpacity(0.06),
      highlightColor: Colors.transparent,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // The tibeb tick — the selection marker, the only gold in the bar.
          AnimatedContainer(
            duration: NorchaMotion.fast,
            curve: Curves.easeOut,
            width: selected ? 16 : 0,
            height: 2,
            margin: const EdgeInsets.only(bottom: 6),
            decoration: BoxDecoration(
              color: NorchaPalette.gold,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          Icon(selected ? spec.activeIcon : spec.icon, size: 22, color: colour),
          const SizedBox(height: 3),
          Text(
            spec.label,
            style: NorchaType.bodySmall.copyWith(
              fontSize: 10.5,
              letterSpacing: 0.3,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: colour,
            ),
          ),
        ],
      ),
    );
  }
}

/// The shared page header. All five pages use this, so the app has one header
/// geometry instead of five slightly different ones.
class NorchaHeader extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String? amharic;
  final Widget? trailing;

  const NorchaHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    this.amharic,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(eyebrow.toUpperCase(), style: NorchaType.sectionLabel),
              const Spacer(),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 10),
          Cloth.tibeb(),
          const SizedBox(height: 14),
          Text(title, style: NorchaType.display),
          if (amharic != null) ...[
            const SizedBox(height: 6),
            Text(
              amharic!,
              style: NorchaType.amharic.copyWith(
                fontSize: 16,
                color: NorchaPalette.inkSoft,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
