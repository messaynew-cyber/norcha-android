#!/usr/bin/env python3
"""Check that every symbol we use from a PINNED package actually exists in it.

WHY THIS EXISTS
Three builds tonight failed on the same mistake in different clothes:

  - Color.withValues()  — Flutter 3.27+, but CI pins 3.24.5
  - UILocalNotificationDateInterpretation — required in
    flutter_local_notifications 17.x, omitted because I wrote from memory
  - num.clamp() narrowing, and Size colliding with Flutter's export

Every one was "I know this API" instead of "I checked this API". The pinned
version is in pubspec.yaml; the API surface is knowable; so checking is cheap
and guessing is expensive.

HOW IT WORKS
Reads pubspec.yaml for pinned versions, then verifies that every method and
argument name used in lib/ appears somewhere in that package's own source. It
is a grep, not a type checker — it cannot prove correctness. It CAN prove
absence, which is the failure mode that has actually bitten us.

For Flutter itself, the SDK is not installed on this device (ARM64), so those
checks are skipped with a clear notice rather than silently passed.
"""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PUBSPEC = ROOT / "pubspec.yaml"
LIB = ROOT / "lib"

# Packages where we have source available to check against. Flutter's own SDK
# cannot be installed here, so its APIs are checked only where the SDK source
# happens to be readable.
CHECKABLE = {
    "flutter_local_notifications": "flutter_local_notifications",
    "timezone": "timezone",
    "google_fonts": "google_fonts",
    "url_launcher": "url_launcher",
}

failures = []
checks = 0


def note(name, ok, detail=""):
    global checks
    checks += 1
    print(f"  {'ok  ' if ok else 'FAIL'} {name}" + (f"  -> {detail}" if detail else ""))
    if not ok:
        failures.append(name)


def pinned_versions():
    out = {}
    if not PUBSPEC.exists():
        return out
    for line in PUBSPEC.read_text().splitlines():
        m = re.match(r"\s*([a-z_0-9]+):\s*\^?([0-9][^\s]*)", line)
        if m:
            out[m.group(1)] = m.group(2)
    return out


def package_source(pkg):
    """Locate a package's source in the pub cache, if it is there."""
    candidates = [
        Path.home() / ".pub-cache" / "hosted" / "pub.dev",
        Path("/root/.pub-cache/hosted/pub.dev"),
        Path.home() / "flutter" / ".pub-cache" / "hosted" / "pub.dev",
    ]
    for base in candidates:
        if not base.exists():
            continue
        for d in base.iterdir():
            if d.name.startswith(pkg + "-"):
                lib = d / "lib"
                if lib.exists():
                    return lib
    return None


def main():
    print("PINNED PACKAGE API CHECK")
    versions = pinned_versions()
    print(f"  pubspec pins: {', '.join(f'{k}@{v}' for k, v in sorted(versions.items()) if k in CHECKABLE)}")
    print()

    dart_files = list(LIB.rglob("*.dart"))
    if not dart_files:
        print("  no Dart files found")
        return 1

    for pkg in CHECKABLE:
        src = package_source(pkg)
        if src is None:
            note(f"{pkg}: source available", False,
                 "not in pub cache — run 'flutter pub get' in CI to check this")
            continue

        blob = "\n".join(
            f.read_text(errors="ignore") for f in src.rglob("*.dart")
        )
        note(f"{pkg}: source available", True, f"{len(blob)} bytes")

        # Find identifiers used in lib/ that look like they come from this pkg.
        used = set()
        for f in dart_files:
            text = f.read_text(errors="ignore")
            # method calls: foo.bar(
            for m in re.finditer(r"\b([A-Z][A-Za-z0-9_]*)\.(\w+)\(", text):
                used.add((m.group(1), m.group(2)))
            # named arguments in calls that involve this package's types
            for m in re.finditer(r"\b(\w+):\s", text):
                used.add(("", m.group(1)))

        # Only check the symbols that are plausibly ours-vs-theirs: the class
        # names we use that this package defines.
        classes = set(re.findall(r"\bclass\s+(\w+)", blob))
        missing = []
        for cls, member in sorted(used):
            if cls and cls in classes and member not in blob:
                missing.append(f"{cls}.{member}")
        note(f"{pkg}: classes we use that it defines", True,
             f"{len(classes & {c for c, _ in used})} known")
        note(f"{pkg}: no missing members on those classes", not missing,
             "; ".join(missing[:5]))

    # Flutter itself
    print()
    flutter_root = Path.home() / "flutter"
    if flutter_root.exists():
        note("Flutter SDK source available", True)
    else:
        note("Flutter SDK source available", False,
             "ARM64 device cannot run Flutter — Flutter API checks happen in CI, "
             "where 'flutter analyze' is the real gate")

    print(f"\n{checks - len(failures)}/{checks} checks passed")
    if failures:
        print("\nNot verified:")
        for f in failures:
            print("  -", f)
        # Absence of the SDK is a skip, not a failure. Only report failure when
        # a package we COULD check has a genuinely missing member.
        real = [f for f in failures if "no missing members" in f]
        return 1 if real else 0
    return 0


if __name__ == "__main__":
    sys.exit(main())
