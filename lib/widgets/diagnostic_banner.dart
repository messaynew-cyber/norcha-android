// Norcha Print — the diagnostic banner.
//
// 🔴 WHY THIS EXISTS
// A bug was reported twice: switching to Amharic left the Order and Upload
// bodies painting as a flat grey rectangle, in a colour that appears nowhere
// in this app's palette. Two fixes were attempted from reading source code,
// and both were wrong. The failure does not reproduce in a widget test, the
// Flutter test font has imaginary metrics, and reading logcat requires the app
// to be running at the moment someone looks.
//
// Guessing from a screenshot does not work. So the app now reports on itself.
//
// This banner catches every error Flutter would otherwise swallow or print to
// a console nobody is watching, keeps the last few, and shows them ON TOP of
// the page. A screenshot then carries the cause, not just the symptom.
//
// 💡 IT IS ALWAYS PRESENT, EVEN WHEN THERE IS NO ERROR. That is deliberate: a
// banner that only appears when something breaks is one more thing that can
// fail to appear. This one says "no errors" and shows a build tag, which also
// answers "which APK am I running?" — a question that cost real time during
// the investigation above.
//
// It is dismissible and remembers that, so it never obstructs normal use.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/version.dart';

/// Holds captured errors for the session. Deliberately a plain static list:
/// this is diagnostic furniture, not application state, and it must work even
/// if the widget tree itself is the thing that is broken.
class Diagnostics {
  static final List<String> _errors = <String>[];
  static final ValueNotifier<int> revision = ValueNotifier<int>(0);

  static List<String> get errors => List.unmodifiable(_errors);
  static bool get hasErrors => _errors.isNotEmpty;

  static void record(String label, Object error, [StackTrace? stack]) {
    final firstFrame = stack == null
        ? ''
        : stack.toString().split('\n').take(4).join(' | ');
    final entry = '$label\n$error${firstFrame.isEmpty ? '' : '\n$firstFrame'}';
    // Keep it short. Ten full Flutter stacks would not fit on a phone screen
    // and the first two are almost always the informative ones.
    _errors.add(entry.length > 700 ? '${entry.substring(0, 700)}…' : entry);
    if (_errors.length > 5) _errors.removeAt(0);
    revision.value++;
    // Also to the console, so a logcat capture still works.
    debugPrint('[NORCHA-DIAG] $label :: $error');
  }

  static void clear() {
    _errors.clear();
    revision.value++;
  }
}

/// Wraps the app and overlays the banner.
class DiagnosticHost extends StatefulWidget {
  final Widget child;
  const DiagnosticHost({super.key, required this.child});

  @override
  State<DiagnosticHost> createState() => _DiagnosticHostState();
}

class _DiagnosticHostState extends State<DiagnosticHost> {
  // Starts EXPANDED so the very first screenshot already carries the build
  // tag and any captured error. Collapsing is one tap and the choice sticks
  // for the session. The whole point of this widget is that a screenshot must
  // not depend on the person remembering to open it.
  bool _collapsed = false;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: Diagnostics.revision,
      builder: (context, _, __) {
        final n = Diagnostics.errors.length;
        final bad = n > 0;
        return Stack(
          children: [
            widget.child,
            // Bottom-anchored so it never covers the page header, which is the
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
                    if (!_collapsed)
                      _Body(errors: Diagnostics.errors),
                    _Bar(
                      bad: bad,
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
