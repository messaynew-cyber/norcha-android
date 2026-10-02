// Norcha Print — the live site API client.
//
// CONTRACT: docs/API-CONTRACT.md. Reference implementation:
// feven-prints-v2/js/norcha-order.js and functions/api/*.js
//
// WHY THIS FILE IS SO CAREFUL ABOUT FAILURES
// The website's /api/order endpoint answers unknown-code, wrong-phone and
// unreadable-record identically and on purpose — if it told you which one was
// wrong, it would confirm to a stranger whether an order exists. A client that
// "helpfully" splits those cases into different messages undoes that, from the
// outside, without touching the server.
//
// So: the app shows ONE message for every 404. It does not guess. It does not
// say "check the phone number" — because it does not know that.
//
// The other thing this file refuses to do is pretend. The API returns
// stage: "received" and says a person still confirms sizes and price. Copy
// anywhere in the app that implies the job is printed or ready is a lie the
// shop has to answer for at the counter.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Where the live site lives. GitHub Pages is a mirror — never point here at it.
const String kNorchaApiBase = 'https://norchaprint.com';

/// A customer, in both languages. The order screen is the one place a customer
/// reads under stress, so it gets first-class Amharic.
class Bi {
  final String en;
  final String am;
  const Bi(this.en, this.am);
  String call(String lang) => lang == 'am' ? am : en;
}

/// What the studio actually received. Not "the order status" — there is no
/// such thing, and inventing one would be the exact lie this project avoids.
class OrderRecord {
  final String code;
  final DateTime? received;
  final int files;
  final int bytes;
  final String stage;
  final String stageNote;
  final String product;
  final String size;
  final String qty;
  final String note;
  final int retentionDays;
  final DateTime? deleteAfter;

  const OrderRecord({
    required this.code,
    required this.received,
    required this.files,
    required this.bytes,
    required this.stage,
    required this.stageNote,
    required this.product,
    required this.size,
    required this.qty,
    required this.note,
    required this.retentionDays,
    required this.deleteAfter,
  });

  /// "Canvas prints · 40 × 60 cm ×2" — the human restatement of what was asked
  /// for. Empty parts are dropped rather than rendered as blanks, because
  /// "·  · ×" on screen looks broken.
  String get requestedSummary {
    final parts = <String>[
      if (product.isNotEmpty) product,
      if (size.isNotEmpty) size,
      if (qty.isNotEmpty) '×$qty',
      if (note.isNotEmpty) note,
    ];
    return parts.isEmpty ? '—' : parts.join(' · ');
  }
}

/// Every way a lookup can end. Modelled explicitly rather than thrown, because
/// the UI has to tell four different stories and none of them is an exception.
enum LookupStatus {
  found,
  /// 404 — and per the contract this covers unknown code, wrong phone AND an
  /// unreadable record. Do not try to narrow it.
  notFound,
  /// 400 — the code or phone did not survive client-side validation.
  invalidInput,
  /// 429
  rateLimited,
  /// 503 — the bucket is not bound. The feature is off, not broken.
  notConfigured,
  /// Transport failure. The server never answered.
  networkError,
}

class LookupResult {
  final LookupStatus status;
  final OrderRecord? record;
  /// Ready-to-show text, EN + AM, chosen by the UI's language.
  final Bi? message;

  const LookupResult(this.status, {this.record, this.message});

  bool get ok => status == LookupStatus.found;
}

class UploadProbe {
  final bool configured;
  final int maxFiles;
  final int maxPerFileMb;
  final int maxTotalMb;
  const UploadProbe({
    required this.configured,
    this.maxFiles = 40,
    this.maxPerFileMb = 25,
    this.maxTotalMb = 200,
  });

  static const UploadProbe off = UploadProbe(configured: false);
}

class UploadResult {
  final bool ok;
  final String? code;
  final int stored;
  final Bi? message;
  const UploadResult({required this.ok, this.code, this.stored = 0, this.message});
}

class NorchaApi {
  /// RFC4122-safe-ish correlation id; not security, just traceability in logs.
  static String _rid() =>
      DateTime.now().microsecondsSinceEpoch.toRadixString(36);

  /// GET /api/order — the honest order lookup.
  ///
  /// [lang] only affects wording; the server answers in English and the app
  /// localises, exactly as the website does.
  static Future<LookupResult> lookupOrder(
    String code,
    String phone, {
    String lang = 'en',
  }) async {
    final c = code.trim().toUpperCase();
    final p = phone.trim();

    if (c.isEmpty || p.isEmpty) {
      return const LookupResult(LookupStatus.invalidInput,
          message: Bi(
            'Please fill in both the reference and the phone number.',
            'እባክዎ ሁለቱንም ይሙሉ።',
          ));
    }

    final uri = Uri.parse('$kNorchaApiBase/api/order').replace(queryParameters: {
      'code': c,
      'phone': p,
    });

    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 15);
      final req = await client.getUrl(uri);
      req.headers.set(HttpHeaders.acceptHeader, 'application/json');
      req.headers.set('X-Request-Id', _rid());
      final res = await req.close().timeout(const Duration(seconds: 15));
      final body = await res.transform(utf8.decoder).join();
      client.close(force: true);

      Map<String, dynamic> json;
      try {
        json = jsonDecode(body) as Map<String, dynamic>;
      } catch (_) {
        return const LookupResult(LookupStatus.networkError,
            message: const Bi(
              'We could not reach the studio. Check your connection and try again.',
              'ከስቱዲዮ ጋር መገናኘት አልቻልንም። ኢንተርኔትዎን ያረጋግጡ።',
            ));
      }

      switch (res.statusCode) {
        case 200:
          return LookupResult(LookupStatus.found, record: _recordFrom(json));
        case 400:
          return LookupResult(LookupStatus.invalidInput,
              message: Bi(
                (json['message'] as String?) ??
                    'Please fill in both the reference and the phone number.',
                'እባክዎ ሁለቱንም ይሙሉ።',
              ));
        case 404:
          // 🔴 ONE message for every 404 — see the note at the top of this file.
          return const LookupResult(LookupStatus.notFound,
              message: const Bi(
                'We could not find an order with that reference and phone number. Check both, or message us on WhatsApp.',
                'በዚህ ቁጥር እና ስልክ ቁጥር ትዕዛዝ አልተገኘም። ሁለቱንም ያረጋግጡ ወይም በዋትስአፕ ያግኙን።',
              ));
        case 429:
          return const LookupResult(LookupStatus.rateLimited,
              message: const Bi(
                'Too many checks from this connection. Please try again later, or message us on WhatsApp.',
                'ከዚህ ግንኙነት ብዙ ጊዜ ተፈልጎዋል። ቆይተው ይሞክሩ ወይም በዋትስአፕ ያግኙን።',
              ));
        case 503:
          return const LookupResult(LookupStatus.notConfigured,
              message: const Bi(
                'Order lookup is not switched on yet. Message us on WhatsApp and we will check for you.',
                'የትዕዛዝ ፍለጋ ገና አልተከፈተም። በዋትስአፕ ያግኙን።',
              ));
        default:
          return const LookupResult(LookupStatus.networkError,
              message: const Bi(
                'Something went wrong on our side. Please message us on WhatsApp.',
                'በእኛ በኩል ችግር ተፈጥሯል። በዋትስአፕ ያግኙን።',
              ));
      }
    } on TimeoutException {
      return const LookupResult(LookupStatus.networkError,
          message: const Bi(
            'That took too long. Check your connection and try again.',
            'ጊዜው አልፎበታል። ኢንተርኔትዎን ያረጋግጡ።',
          ));
    } catch (_) {
      return const LookupResult(LookupStatus.networkError,
          message: const Bi(
            'We could not reach the studio. Check your connection and try again.',
            'ከስቱዲዮ ጋር መገናኘት አልቻልንም። ኢንተርኔትዎን ያረጋግጡ።',
          ));
    }
  }

  static OrderRecord _recordFrom(Map<String, dynamic> j) {
    final r = (j['requested'] as Map?) ?? const {};
    return OrderRecord(
      code: (j['code'] as String?) ?? '',
      received: _parseDate(j['received']),
      files: (j['files'] as num?)?.toInt() ?? 0,
      bytes: (j['bytes'] as num?)?.toInt() ?? 0,
      stage: (j['stage'] as String?) ?? 'received',
      stageNote: (j['stage_note'] as String?) ?? '',
      product: (r['product'] as String?) ?? '',
      size: (r['size'] as String?) ?? '',
      qty: (r['qty'] as String?) ?? '',
      note: (r['note'] as String?) ?? '',
      retentionDays: (j['retention_days'] as num?)?.toInt() ?? 30,
      deleteAfter: _parseDate(j['delete_after']),
    );
  }

  static DateTime? _parseDate(Object? v) {
    if (v is! String || v.isEmpty) return null;
    return DateTime.tryParse(v);
  }

  /// GET /api/upload — the probe.
  ///
  /// 🔴 Call this BEFORE showing any upload affordance. A 503 means the R2
  /// bucket is not bound, and the correct response is to hide the entry point
  /// completely, not to show a box that cannot deliver.
  static Future<UploadProbe> probeUpload() async {
    final uri = Uri.parse('$kNorchaApiBase/api/upload');
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 10);
      final req = await client.getUrl(uri);
      req.headers.set(HttpHeaders.acceptHeader, 'application/json');
      final res = await req.close().timeout(const Duration(seconds: 10));
      final body = await res.transform(utf8.decoder).join();
      client.close(force: true);
      if (res.statusCode != 200) return UploadProbe.off;
      final j = jsonDecode(body) as Map<String, dynamic>;
      if (j['ok'] != true) return UploadProbe.off;
      return UploadProbe(
        configured: true,
        maxFiles: (j['maxFiles'] as num?)?.toInt() ?? 40,
        maxPerFileMb: (j['maxPerFileMb'] as num?)?.toInt() ?? 25,
        maxTotalMb: (j['maxTotalMb'] as num?)?.toInt() ?? 200,
      );
    } catch (_) {
      // No signal at the counter is normal. Absent, not broken.
      return UploadProbe.off;
    }
  }
}

/// The honeypot field name. Bots fill it; humans never see it. Sent empty on
/// every legitimate request — mirrors the website exactly.
const String kHoneypotField = 'website';
