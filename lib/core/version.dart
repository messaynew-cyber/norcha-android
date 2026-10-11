// Norcha Print — which build is this?
//
// WHY THIS FILE EXISTS
// Diagnosing a report from a phone is impossible without knowing which binary
// produced it. During the Amharic investigation the version on the About page
// was a hardcoded 'v0.3' that had not been touched in four builds, so it told
// us nothing — and a screenshot cannot be trusted to identify itself either.
//
// The values below are DEFAULTS for a local or IDE run. CI overwrites them
// before building so a shipped APK carries its real identity:
//
//     flutter build apk --release \
//       --dart-define=NORCHA_VERSION=0.5.0+42 --dart-define=NORCHA_SHA=$GITHUB_SHA
//
// 🔴 THE VERSION COMES FROM /VERSION, NOT FROM THE RUN NUMBER.
// It used to be `0.4.${{ github.run_number }}`, which meant the number on the
// About page tracked how many times CI had run — not what the app was. Two
// builds of the same source reported different versions, and a version could
// never be compared to a tag or a changelog. Now CI reads /VERSION and appends
// `+<run number>` so identity is BOTH human and unambiguous:
//
//     VERSION file      ->  0.5.0
//     run number        ->  42
//     stamped version   ->  0.5.0+42
//
// Never hardcode a version anywhere else. Read it from here.

class NorchaVersion {
  /// Set by CI. 'dev' means this was not a CI build.
  static const String version =
      String.fromEnvironment('NORCHA_VERSION', defaultValue: 'dev');

  /// The commit this was built from, or 'local'.
  static const String sha =
      String.fromEnvironment('NORCHA_SHA', defaultValue: 'local');

  /// Short form for the About page: "v0.4.25 · a1b2c3d"
  static String get display {
    if (version == 'dev') return 'dev build';
    final short = sha.length >= 7 ? sha.substring(0, 7) : sha;
    return 'v$version · $short';
  }

  /// One line, for a log or a support screenshot.
  static String get full => 'Norcha Print $version ($sha)';
}
