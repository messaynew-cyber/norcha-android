// Language layer tests.
//
// Norcha's counter speaks Amharic first. These tests exist so that the Amharic
// cannot quietly rot — a missing translation, a duplicated key, or a page that
// silently falls back to English are all failures worth catching in CI rather
// than in front of a customer.

import 'package:flutter_test/flutter_test.dart';
import 'package:norcha_print/core/lang.dart';

void main() {
  group('both languages are always present', () {
    test('every key has a non-empty English string', () {
      for (final k in _allKeys()) {
        final v = L.t(k, NorchaLang.en);
        expect(v, isNotEmpty, reason: '$k has no English');
        expect(v, isNot(k), reason: '$k fell through to the key (missing entry)');
      }
    });

    test('every key has a non-empty Amharic string', () {
      for (final k in _allKeys()) {
        final v = L.t(k, NorchaLang.am);
        expect(v, isNotEmpty, reason: '$k has no Amharic');
        expect(v, isNot(k), reason: '$k fell through to the key (missing entry)');
      }
    });

    test('no string is identical in both languages except deliberate ones', () {
      // Acronyms and proper nouns are legitimately the same word in both. A
      // long string being identical is almost always an un-translated copy.
      const allowed = {
        'nav.studio', 'studio.whatsapp', 'order.whatsapp', 'upload.waSend',
        'upload.refWa', 'set.lang',
      };
      for (final k in _allKeys()) {
        if (allowed.contains(k)) continue;
        final (en, am) = L.both(k);
        if (en.length > 12) {
          expect(am, isNot(en),
              reason: '$k looks un-translated — identical in both languages');
        }
      }
    });
  });

  group('Amharic strings are actually Amharic', () {
    test('the Amharic contains Ethiopic codepoints', () {
      // U+1200..U+137F is the Ethiopic block. A "translation" with no Ethiopic
      // characters is an English string in the wrong slot.
      final ethiopic = RegExp(r'[\u1200-\u137F]');
      for (final k in _allKeys()) {
        if (k == 'studio.whatsapp' || k == 'order.whatsapp') continue;
        final (_, am) = L.both(k);
        expect(ethiopic.hasMatch(am), isTrue,
            reason: '$k has no Ethiopic characters: "$am"');
      }
    });

    test('Amharic input reaches the Ge\'ez numerals without collision', () {
      // The ghost numerals are U+1369..U+1372, inside the Ethiopic block. If a
      // translated string ever contains one by accident it would render as a
      // stray numeral mid-sentence.
      final geezDigit = RegExp(r'[\u1369-\u1372]');
      for (final k in _allKeys()) {
        final (_, am) = L.both(k);
        expect(geezDigit.hasMatch(am), isFalse,
            reason: '$k contains a Ge\'ez numeral character');
      }
    });
  });

  group('the language switch', () {
    test('parses only what it knows, and defaults to English', () {
      expect(NorchaLang.parse('am'), NorchaLang.am);
      expect(NorchaLang.parse('en'), NorchaLang.en);
      expect(NorchaLang.parse(null), NorchaLang.en);
      expect(NorchaLang.parse('fr'), NorchaLang.en);
      expect(NorchaLang.parse(''), NorchaLang.en);
    });

    test('the codes match what the API accepts', () {
      // upload.js sends `lang` and expects 'en' or 'am' exactly.
      expect(NorchaLang.en.code, 'en');
      expect(NorchaLang.am.code, 'am');
    });
  });

  group('missing keys are loud, not silent', () {
    test('an unknown key returns itself rather than English', () {
      // Falling back to English would render the WRONG LANGUAGE on screen with
      // no sign anything was wrong. Returning the key makes it visible.
      expect(L.t('does.not.exist', NorchaLang.am), 'does.not.exist');
    });
  });
}

/// Every key the app defines. Kept here rather than exported from L so that a
/// key added without a test still shows up as a missing entry in the loop.
List<String> _allKeys() => const [
  'nav.home', 'nav.quote', 'nav.order', 'nav.upload', 'nav.studio',
  'home.eyebrow', 'home.title', 'home.hero.kicker', 'home.hero.line',
  'home.section.products', 'home.section.find', 'home.sizes', 'home.sameDay',
  'home.days', 'home.day', 'home.orderWithin', 'home.lastDayToday', 'home.from',
  'quote.eyebrow', 'quote.title', 'quote.size', 'quote.howMany', 'quote.when',
  'quote.breakdown', 'quote.unit', 'quote.qty', 'quote.subtotal',
  'quote.discount', 'quote.total', 'quote.send', 'quote.pickDate',
  'quote.needBy', 'quote.readyToday', 'quote.readyTomorrow', 'quote.ready',
  'quote.tierUnlock', 'quote.applied', 'quote.past', 'quote.sunday',
  'quote.tight', 'quote.tempWarn',
  'order.eyebrow', 'order.title', 'order.blurb', 'order.ref', 'order.phone',
  'order.check', 'order.checking', 'order.found', 'order.received',
  'order.arrived', 'order.asked', 'order.deleted', 'order.whatsapp',
  'order.another',
  'upload.eyebrow', 'upload.title', 'upload.blurb', 'upload.choose',
  'upload.again', 'upload.selected', 'upload.upTo', 'upload.forWhat',
  'upload.sizeOpt', 'upload.yourName', 'upload.phone', 'upload.note',
  'upload.optional', 'upload.send', 'upload.sendN', 'upload.sending',
  'upload.sent', 'upload.keepChat', 'upload.offTitle', 'upload.offBody',
  'upload.waSend', 'upload.received', 'upload.yourRef', 'upload.keepRef',
  'upload.refWa',
  'studio.eyebrow', 'studio.title', 'studio.findUs', 'studio.cutoff',
  'studio.maps', 'studio.talk', 'studio.whatsapp', 'studio.call',
  'studio.howLong', 'studio.timingNote', 'studio.yourPhotos',
  'studio.retention', 'studio.privacy',
  'set.theme.light', 'set.theme.dark', 'set.lang', 'set.appearance',
];
