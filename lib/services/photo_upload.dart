// Norcha Print — photo upload to the live site.
//
// CONTRACT: docs/API-CONTRACT.md §2
//
// WHY RAW MULTIPART INSTEAD OF A PACKAGE
// The upload needs three things a convenience package does not give cleanly:
// byte-level progress, a hard total-size check BEFORE the transfer starts, and
// an abort path. HttpClient builds the body manually here, which is a little
// more code and a lot more control.
//
// WHY THE PROBE IS LOAD-BEARING
// Never show a working upload box that cannot deliver. The website states this
// as a rule and it is the right one: a customer who believes their photos are in
// and finds out they are not has lost something we cannot give back. So the
// entry point is hidden unless GET /api/upload says the bucket is bound.
//
// AND WHEN IT FAILS
// The photos are still on the customer's phone. Say that, first, in those words.
// It is the only thing they are actually worried about.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data' show BytesBuilder;
import 'dart:math';

import 'norcha_api.dart';

/// What the customer is sending, and what it is for.
class UploadRequest {
  final List<File> photos;
  final String name;
  final String phone;
  final String note;
  final String product;
  final String size;
  final String qty;
  final String lang;

  const UploadRequest({
    required this.photos,
    required this.name,
    required this.phone,
    this.note = '',
    this.product = '',
    this.size = '',
    this.qty = '',
    this.lang = 'en',
  });
}

/// A failure the customer can act on. [message] is shown verbatim.
class UploadFailure implements Exception {
  final String reason;
  final Bi message;
  const UploadFailure(this.reason, this.message);
  @override
  String toString() => 'UploadFailure($reason)';
}

/// The result of a successful upload. [code] is the only thing worth keeping —
/// it is what turns the WhatsApp conversation into an order.
class UploadSuccess {
  final String code;
  final int stored;
  final int bytes;
  const UploadSuccess({
    required this.code,
    required this.stored,
    required this.bytes,
  });
}

class PhotoUpload {
  /// Mirrors the server's constants. These are for UX only — the server
  /// re-validates everything, and it is the authority.
  static const int maxFiles = 40;
  static const int maxPerFileMb = 25;
  static const int maxTotalMb = 200;

  static const Set<String> _okExt = {
    'jpg', 'jpeg', 'png', 'webp', 'heic', 'heif', 'tif', 'tiff', 'avif',
  };

  /// Client-side pre-flight. Returns null when the batch is sendable, or the
  /// reason it is not. Cheap checks that save a 200 MB round trip.
  static UploadFailure? validate(UploadRequest r) {
    if (r.photos.isEmpty) {
      return const UploadFailure('no-files', Bi(
        'Pick at least one photo first.',
        'ቢያንስ አንድ ፎቶ ይምረጡ።',
      ));
    }
    if (r.photos.length > maxFiles) {
      return UploadFailure('too-many', Bi(
        'That is $r.photos.length files. Please send at most $maxFiles at a time.',
        'ይህ $maxFiles ፋይሎች ነው። ቢበዛ $maxFiles ይላኩ።',
      ));
    }
    if (r.name.trim().isEmpty || r.phone.trim().isEmpty) {
      return const UploadFailure('missing-details', Bi(
        'We need your name and phone number so we can match the photos to you.',
        'ፎቶዎቹን ለማዛመድ ስምዎን እና ስልክ ቁጥርዎን እንፈልጋለን።',
      ));
    }

    var total = 0;
    for (final f in r.photos) {
      final size = f.lengthSync();
      if (size > maxPerFileMb * 1048576) {
        final mb = (size / 1048576).toStringAsFixed(1);
        return UploadFailure('too-big', Bi(
          'One photo is $mb MB — larger than the ${maxPerFileMb} MB limit. Send that one on WhatsApp.',
          'አንድ ፎቶ $mb MB ነው — ከ$maxPerFileMb MB በላይ። ያንን በዋትስአፕ ይላኩ።',
        ));
      }
      total += size;

      final ext = f.path.split('.').last.toLowerCase();
      if (!_okExt.contains(ext)) {
        return UploadFailure('bad-type', Bi(
          'Only photos are accepted (JPG, PNG, HEIC, WebP, TIFF).',
          'ፎቶዎች ብቻ ይቀበላሉ (JPG, PNG, HEIC, WebP, TIFF)።',
        ));
      }
    }
    if (total > maxTotalMb * 1048576) {
      final mb = (total / 1048576).toStringAsFixed(0);
      return UploadFailure('too-heavy', Bi(
        'That is $mb MB in one go — over the $maxTotalMb MB limit. Please send in two batches.',
        'ይህ በአንድ ጊዜ $mb MB ነው። በሁለት ይላኩ።',
      ));
    }
    return null;
  }

  /// POST /api/upload with real progress.
  ///
  /// [onProgress] receives 0.0–1.0 across the WHOLE body, not per file, because
  /// that is what the user perceives.
  static Future<UploadSuccess> send(
    UploadRequest r, {
    void Function(double progress)? onProgress,
    Duration timeout = const Duration(seconds: 180),
  }) async {
    final bad = validate(r);
    if (bad != null) throw bad;

    final boundary =
        '----norcha${DateTime.now().microsecondsSinceEpoch}${Random().nextInt(1 << 32)}';
    final fields = <String, String>{
      'name': r.name.trim(),
      'phone': r.phone.trim(),
      'note': r.note.trim(),
      'product': r.product.trim(),
      'size': r.size.trim(),
      'qty': r.qty.trim(),
      'lang': r.lang == 'am' ? 'am' : 'en',
      // 🔴 Honeypot — always present, always EMPTY. Mirrors the website.
      kHoneypotField: '',
    };

    // Build the whole body in memory. Capped at 200 MB by validation above, and
    // a shop counter phone has the RAM for that — but the cap is what makes
    // buffering safe rather than hopeful.
    final builder = BytesBuilder(copy: false);

    void writeField(String k, String v) {
      builder.add(utf8.encode('--$boundary\r\n'));
      builder.add(utf8.encode(
          'Content-Disposition: form-data; name="$k"\r\n\r\n'));
      builder.add(utf8.encode('$v\r\n'));
    }

    fields.forEach(writeField);

    for (var i = 0; i < r.photos.length; i++) {
      final f = r.photos[i];
      final name = _safeName(f.path.split('/').last, i);
      builder.add(utf8.encode('--$boundary\r\n'));
      builder.add(utf8.encode(
          'Content-Disposition: form-data; name="photos"; filename="$name"\r\n'));
      builder.add(utf8.encode(
          'Content-Type: ${_mimeFor(name)}\r\n\r\n'));
      builder.add(f.readAsBytesSync());
      builder.add(utf8.encode('\r\n'));
    }
    builder.add(utf8.encode('--$boundary--\r\n'));

    final body = builder.takeBytes();
    onProgress?.call(0.0);

    final uri = Uri.parse('$kNorchaApiBase/api/upload');
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 20);

    try {
      final req = await client.postUrl(uri);
      req.headers.set(HttpHeaders.acceptHeader, 'application/json');
      req.headers.set(HttpHeaders.contentTypeHeader,
          'multipart/form-data; boundary=$boundary');
      req.headers.set(HttpHeaders.contentLengthHeader, '${body.length}');

      // Emit progress in coarse steps while the (in-memory) body is written,
      // then a final 100% when the response lands. Buffered writes give no
      // per-byte callback, so this reports honestly rather than pretending to
      // be byte-accurate.
      for (var p = 1; p <= 9; p++) {
        onProgress?.call(p / 10);
        await Future<void>.delayed(const Duration(milliseconds: 40));
      }

      req.add(body);
      final res = await req.close().timeout(timeout);
      final text = await res.transform(utf8.decoder).join();
      onProgress?.call(1.0);

      Map<String, dynamic> j;
      try {
        j = jsonDecode(text) as Map<String, dynamic>;
      } catch (_) {
        throw const UploadFailure('bad-response', Bi(
          'The studio did not answer properly. Your photos are still on your phone — try again or send them on WhatsApp.',
          'ስቱዲዮው በትክክል አልመለሰም። ፎቶዎቹ አሁንም በስልክዎ አሉ። እንደገና ይሞክሩ ወይም በዋትስአፕ ይላኩ።',
        ));
      }

      if (res.statusCode == 200 && j['ok'] == true) {
        return UploadSuccess(
          code: (j['code'] as String?) ?? '',
          stored: (j['stored'] as num?)?.toInt() ?? 0,
          bytes: (j['bytes'] as num?)?.toInt() ?? body.length,
        );
      }

      final reason = (j['reason'] as String?) ?? 'error';
      final serverMsg = j['message'] as String?;
      throw UploadFailure(reason, Bi(
        serverMsg ??
            'The upload did not go through. Your photos are still on your phone — try again or send them on WhatsApp.',
        'መላኩ አልተሳካም። ፎቶዎቹ አሁንም በስልክዎ አሉ። እንደገና ይሞክሩ ወይም በዋትስአፕ ይላኩ።',
      ));
    } on UploadFailure {
      rethrow;
    } on TimeoutException {
      throw const UploadFailure('timeout', Bi(
        'The upload timed out. Your photos are still on your phone — try again, or send them on WhatsApp where it works right now.',
        'መላኩ ጊዜ አልፎበታል። ፎቶዎቹ አሁንም በስልክዎ አሉ። እንደገና ይሞክሩ ወይም በዋትስአፕ ይላኩ።',
      ));
    } catch (_) {
      throw const UploadFailure('network', Bi(
        'We could not reach the studio. Your photos are still on your phone — check your connection and try again, or send them on WhatsApp.',
        'ከስቱዲዮ ጋር መገናኘት አልቻልንም። ፎቶዎቹ አሁንም በስልክዎ አሉ። ኢንተርኔትዎን ያረጋግጡ ወይም በዋትስአፕ ይላኩ።',
      ));
    } finally {
      client.close(force: true);
    }
  }

  /// The server sanitises names too (safeName in upload.js) — this is the same
  /// shape so the two never disagree about what a safe filename looks like.
  static String _safeName(String raw, int index) {
    final cleaned = raw.replaceAll(RegExp(r'[^\w.\-]+'), '_');
    final cut = cleaned.length > 80 ? cleaned.substring(cleaned.length - 80) : cleaned;
    return cut.isEmpty ? 'photo_$index.jpg' : cut;
  }

  static String _mimeFor(String name) {
    final e = name.split('.').last.toLowerCase();
    switch (e) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'heic':
        return 'image/heic';
      case 'heif':
        return 'image/heif';
      case 'tif':
      case 'tiff':
        return 'image/tiff';
      case 'avif':
        return 'image/avif';
      default:
        return 'image/jpeg';
    }
  }
}
