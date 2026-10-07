// Norcha Print — the diagnostic banner.
//
// 🔴 WHY THIS EXISTS
// A bug was reported: switching to Amharic left the Order and Upload bodies
// painting as a flat grey rectangle. Two fixes were attempted from reading
// source code and both were wrong, so the app was given a way to report on
// itself instead of being guessed at.
//
// ⚠️ AND THEN IT CAUSED A WORSE BUG. The first version wrapped MaterialApp
// from OUTSIDE, which put it above Directionality and MediaQuery. It builds a
// Stack with Positioned children, and a Positioned requires a text direction,
// so the app threw on its first build and showed a blank white screen — and
// the banner could not report that error, because the widget that draws the
// banner was inside the thing that broke.
//
// Two lessons, both encoded below:
//   1. This mounts inside MaterialApp.builder, never around it.
//   2. It supplies its own Directionality if the ambient tree has none, so it
//      can never be the reason the app fails to open. A diagnostic tool that
//      can take down the thing it diagnoses is worse than no tool.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/version.dart';

/// Holds captured errors for the session. Deliberately a plain static list:
/// this is diagnostic furniture, not application state, and it must keep
/// working even when the widget tree is the thing that is broken.
class Diagnostics {
  static final List<String> _errors = <String>[];
  static final ValueNotifier<int> revision = ValueNotifier<int>(0);

  static List<String> get errors => List.unmodifiable(_errors);
  static bool get hasErrors => _errors.isNotEmpty;

  static void record(String label, Object error, [StackTrace? stack]) {
    final frames = stack == null
        ? ''
        : stack.toString().split('\n').take(4).join(' | ');
    final entry = '$label\n$error${frames.isEmpty ? '' : '\n$frames'}';
    // Ten full Flutter stacks would not fit on a phone screen, and the first
    // two are nearly always the informative ones.
    _errors.add(entry.length > 700 ? '${entry.substring(0, 700)}…' : entry);
    if (_errors.length > 5) _errors.removeAt(0);
    revision.value++;
    debugPrint('[NORCHA-DIAG] $label :: $error');
  }

  static void clear() {
    _errors.clear();
    revision.value++;
  }
}

/// Draws the banner over [child]. Mount this from MaterialApp's `builder`.
class DiagnosticHost extends StatefulWidget {
  final Widget child;
  const DiagnosticHost({super.key, required this.child});

  @override
  State<DiagnosticHost> createState() => _DiagnosticHostState();
}

class _DiagnosticHostState extends State<DiagnosticHost> {
  // Starts EXPANDED so the first screenshot a person takes already carries the
  // build tag and any captured error. A banner that must be opened first is one
  // more thing that can fail to be opened.
  bool _collapsed = false;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: Diagnostics.revision,
      builder: (context, _, __) {
        final n = Diagnostics.errors.length;
        // Supplied explicitly so this can mount anywhere without throwing.
        // This single line is the fix for the blank white screen.
        return Directionality(
          textDirection: Directionality.maybeOf(context) ?? TextDirection.ltr,
          child: Stack(
            children: [
              widget.child,
              // Bottom-anchored: never covers the page header, which is the
              // part of these pages that has always rendered correctly.
              Positioned(
                left: 8,
                right: 8,
                bottom: 8,
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!_collapsed) _Body(errors: Diagnostics.errors),
                      _Bar(
                        bad: n > 0,
                        count: n,
                        collapsed: _collapsed,
                        onTap: () => setState(() => _collapsed = !_collapsed),
                        onClear: () {
                          Diagnostics.clear();
                          setState(() => _collapsed = true);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Bar extends StatelessWidget {
  final bool bad;
  final int count;
  final bool collapsed;
  final VoidCallback onTap;
  final VoidCallback onClear;

  const _Bar({
    required this.bad,
    required this.count,
    required this.collapsed,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bad ? const Color(0xFF7E211C) : const Color(0xFF17532F),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  bad
                      ? '$count ERROR${count == 1 ? '' : 'S'} — tap to read'
                      : 'no errors · ${NorchaVersion.display}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              if (bad)
                GestureDetector(
                  onTap: onClear,
                  child: const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Text('clear',
                        style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontFamily: 'monospace')),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final List<String> errors;
  const _Body({required this.errors});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xE60B0A09),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF7E211C)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('BUILD',
              style: TextStyle(
                  color: Color(0xFFB8912F),
                  fontSize: 9,
                  letterSpacing: 1.5,
                  fontFamily: 'monospace')),
          const SizedBox(height: 2),
          Text(NorchaVersion.full,
              style: const TextStyle(
                  color: Colors.white, fontSize: 10, fontFamily: 'monospace')),
          const SizedBox(height: 8),
          if (errors.isEmpty)
            const Text('no errors recorded this session',
                style: TextStyle(
                    color: Colors.white54,
                    fontSize: 10,
                    fontFamily: 'monospace'))
          else
            ...errors.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(e,
                      style: const TextStyle(
                          color: Color(0xFFF4EFE6),
                          fontSize: 9.5,
                          height: 1.35,
                          fontFamily: 'monospace')),
                )),
        ],
      ),
    );
  }
}
