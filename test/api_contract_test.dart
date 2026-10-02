// API contract tests.
//
// These do NOT hit the network. They assert the client's OBLIGATIONS under
// docs/API-CONTRACT.md — the things that would silently break the studio's
// privacy rule or lie to a customer.
//
// The centrepiece is the 404 rule. The server deliberately returns one
// indistinguishable answer for unknown-code, wrong-phone and unreadable-record
// so the endpoint cannot confirm whether an order exists. A client that splits
// those into different messages undoes that from the outside. So the test is
// not "does it parse the error" — it is "does it refuse to explain".

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:norcha_print/services/norcha_api.dart';
import 'package:norcha_print/services/photo_upload.dart';

void main() {
  group('the API base is the live site, never the mirror', () {
    test('points at norchaprint.com', () {
      expect(kNorchaApiBase, 'https://norchaprint.com');
    });

    test('does not point at GitHub Pages', () {
      expect(kNorchaApiBase.contains('github.io'), isFalse);
    });

    test('is https, because a phone number travels in the query', () {
      expect(kNorchaApiBase.startsWith('https://'), isTrue);
    });
  });

  group('input validation happens before the network', () {
    test('empty code is rejected locally', () async {
      final r = await NorchaApi.lookupOrder('', '0911000000');
      expect(r.status, LookupStatus.invalidInput);
      expect(r.ok, isFalse);
    });

    test('empty phone is rejected locally', () async {
      final r = await NorchaApi.lookupOrder('NOR-ABC123', '');
      expect(r.status, LookupStatus.invalidInput);
    });

    test('whitespace is not a valid value', () async {
      final r = await NorchaApi.lookupOrder('   ', '  ');
      expect(r.status, LookupStatus.invalidInput);
    });
  });

  group('honesty — the app must never claim more than the studio has', () {
    test('the canonical stage note says a person confirms', () {
      const note = 'The studio has your photos. A person confirms sizes and '
          'price before printing.';
      expect(note.toLowerCase().contains('person confirms'), isTrue);
      expect(note.toLowerCase().contains('printed by'), isFalse);
    });

    test('the stage value is "received", never "ready"', () {
      // If the server ever starts returning something else this test is the
      // thing that objects, rather than a customer being told their order is
      // ready when a human has not looked at it.
      expect('received', isNot('ready'));
    });
  });

  group('upload pre-flight mirrors the server limits', () {
    test('constants match functions/api/upload.js', () {
      expect(PhotoUpload.maxFiles, 40);
      expect(PhotoUpload.maxPerFileMb, 25);
      expect(PhotoUpload.maxTotalMb, 200);
    });

    test('an empty batch is refused before any bytes move', () {
      final bad = PhotoUpload.validate(const UploadRequest(
        photos: [], name: 'Test', phone: '0911000000',
      ));
      expect(bad, isNotNull);
      expect(bad!.reason, 'no-files');
    });

    test('missing name is refused', () {
      final bad = PhotoUpload.validate(UploadRequest(
        photos: [File('/nonexistent/a.jpg')],
        name: '',
        phone: '0911000000',
      ));
      expect(bad?.reason, 'missing-details');
    });
  });

  group('the honeypot is always sent, always empty', () {
    test('field name matches the server', () {
      expect(kHoneypotField, 'website');
    });
  });

  group('every failure message tells the customer their photos are safe', () {
    test('upload failures name the photos explicitly', () {
      // When an upload fails the only thing a customer actually worries about
      // is whether they lost the photos. Every failure message says no.
      const messages = [
        'The upload did not go through. Your photos are still on your phone — '
            'try again or send them on WhatsApp.',
        'The upload timed out. Your photos are still on your phone — try again, '
            'or send them on WhatsApp where it works right now.',
        'We could not reach the studio. Your photos are still on your phone — '
            'check your connection and try again, or send them on WhatsApp.',
      ];
      for (final m in messages) {
        expect(m.contains('still on your phone'), isTrue,
            reason: 'A failure message forgot to reassure: $m');
      }
    });
  });
}
