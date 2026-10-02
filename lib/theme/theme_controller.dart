// Norcha Print — theme controller.
//
// Holds the active mode, persists it, and notifies the app. Deliberately a
// ChangeNotifier rather than a package: this is forty lines of state and adding
// a state-management dependency to an app with five pages would be furniture
// nobody asked for.

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_theme.dart';

class ThemeController extends ChangeNotifier {
  static const _key = 'norcha.theme_mode';

  NorchaThemeMode _mode = NorchaThemeMode.light;
  bool _loaded = false;

  NorchaThemeMode get mode => _mode;
  NorchaColors get colors =>
      _mode == NorchaThemeMode.dark ? NorchaColors.dark : NorchaColors.light;
  bool get isLoaded => _loaded;

  /// Read the saved preference. Failure is silent on purpose: a first launch
  /// with no stored value is normal, and the app must never refuse to open
  /// because a preference could not be read.
  Future<void> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      _mode = NorchaThemeMode.parse(p.getString(_key));
    } catch (_) {
      _mode = NorchaThemeMode.light;
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> set(NorchaThemeMode m) async {
    if (m == _mode) return;
    _mode = m;
    notifyListeners();
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_key, m.key);
    } catch (_) {
      // The switch already happened on screen. Failing to remember it is a
      // smaller problem than refusing to switch.
    }
  }

  Future<void> toggle() => set(
      _mode == NorchaThemeMode.dark ? NorchaThemeMode.light : NorchaThemeMode.dark);
}
