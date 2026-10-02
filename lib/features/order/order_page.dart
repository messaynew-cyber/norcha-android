// Norcha Print — Order lookup. "Did my photos arrive?"
//
// THE HONEST VERSION
// This does not pretend the shop has a live status feed. It answers one real
// question — what did you receive, and when — from the same records the
// uploader wrote. A person at the studio still confirms sizes and price.
//
// 🔴 THE PRIVACY RULE, CARRIED INTO THE UI
// The endpoint deliberately returns ONE indistinguishable answer for unknown
// code, wrong phone and unreadable record, so it can never confirm to a
// stranger whether an order exists. This screen must not undo that by
// guessing which field was wrong. There is one error message for a 404, and
// it names both fields, not the guilty one.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/pricing.dart';
import '../../services/norcha_api.dart';
import '../../theme/netela.dart';
import '../../theme/norcha_theme.dart';
import '../../widgets/cloth_surface.dart';
import '../shell/app_shell.dart';

class OrderPage extends StatefulWidget {
  const OrderPage({super.key});

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  final _code = TextEditingController();
  final _phone = TextEditingController();

  bool _busy = false;
  LookupResult? _result;

  @override
  void dispose() {
    _code.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _result = null;
    });

    final r = await NorchaApi.lookupOrder(_code.text, _phone.text);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _result = r;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          const NorchaHeader(
            eyebrow: 'Order status',
            title: 'Did my photos\narrive?',
            amharic: 'ፎቶዎቼ ደርሰዋል?',
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enter the reference we gave you and the phone number you '
                  'ordered with.',
                  style: NorchaType.bodySmall.copyWith(fontSize: 14),
                ),
                const SizedBox(height: 20),
                _Field(
                  controller: _code,
                  label: 'REFERENCE',
                  hint: 'NOR-ABC123',
                  caps: TextCapitalization.characters,
                  formatters: [
                    // The server's alphabet: no 0/O/1/I/L, so a code can be
                    // read down a phone line without ambiguity.
                    FilteringTextInputFormatter.allow(
                        RegExp(r'[A-Za-z0-9\-]')),
                    LengthLimitingTextInputFormatter(10),
                  ],
                ),
                const SizedBox(height: 14),
                _Field(
                  controller: _phone,
                  label: 'PHONE NUMBER',
                  hint: '09•• ••• •••',
                  keyboard: TextInputType.phone,
                  formatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9+\- ]')),
                  ],
                ),
                const SizedBox(height: 22),
                _PrimaryButton(
                  label: _busy ? 'Checking…' : 'Check my order',
                  busy: _busy,
                  onTap: _busy ? null : _check,
                ),
                const SizedBox(height: 18),
                if (_result != null) _ResultBlock(result: _result!),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputType? keyboard;
  final TextCapitalization caps;
  final List<TextInputFormatter>? formatters;

  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    this.keyboard,
    this.caps = TextCapitalization.none,
    this.formatters,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: NorchaType.sectionLabel),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboard,
          textCapitalization: caps,
          inputFormatters: formatters,
          style: NorchaType.body.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
          cursorColor: NorchaPalette.pine,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: NorchaType.body.copyWith(color: NorchaPalette.inkFaint),
            filled: true,
            fillColor: NorchaPalette.card,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(NorchaShape.sm),
              borderSide: const BorderSide(color: NorchaPalette.line),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(NorchaShape.sm),
              borderSide: const BorderSide(color: NorchaPalette.pine, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

/// The result of a lookup. Renders found OR failed, never both.
class _ResultBlock extends StatelessWidget {
  final LookupResult result;
  const _ResultBlock({required this.result});

  @override
  Widget build(BuildContext context) {
    if (!result.ok) {
      return ClothSurface(
        accent: NorchaPalette.warn,
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline,
                size: 19, color: NorchaPalette.warn),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                result.message?.call('en') ??
                    'We could not check that. Please try again.',
                style: NorchaType.bodySmall.copyWith(
                  fontSize: 14,
                  color: NorchaPalette.ink,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final r = result.record!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClothSurface(
          accent: NorchaPalette.pine,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: NorchaPalette.pine.withOpacity(0.10),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_rounded,
                        size: 18, color: NorchaPalette.pine),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('We have your photos',
                        style: NorchaType.title.copyWith(fontSize: 18)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // The reference, selectable — the customer will paste this into
              // WhatsApp, so it must be copyable in one gesture.
              SelectableText(
                r.code,
                style: NorchaType.title.copyWith(
                  fontSize: 26,
                  letterSpacing: 1.5,
                  color: NorchaPalette.pine,
                ),
              ),
              const SizedBox(height: 16),
              const Divider(color: NorchaPalette.line, height: 1),
              const SizedBox(height: 14),
              _Row('Photos received', '${r.files}'),
              if (r.received != null)
                _Row('Received', _fmtDate(r.received!)),
              if (r.requestedSummary != '—')
                _Row('You asked for', r.requestedSummary),
              if (r.deleteAfter != null)
                _Row('We delete them on', _fmtDate(r.deleteAfter!)),
              const SizedBox(height: 14),
              // The honest label. The studio has the files; a human still has to
              // print them. Saying "ready" here would be a lie the shop has to
              // answer for at the counter.
              Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: NorchaPalette.paperDeep,
                  borderRadius: BorderRadius.circular(NorchaShape.xs),
                ),
                child: Text(
                  r.stageNote.isEmpty
                      ? 'The studio has your photos. A person confirms sizes '
                          'and price before printing.'
                      : r.stageNote,
                  style: NorchaType.bodySmall.copyWith(fontSize: 12.5),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _PrimaryButton(
          label: 'Message us on WhatsApp',
          onTap: () => launchUrl(
            Uri.parse('https://wa.me/${Shop.wa}?text='
                '${Uri.encodeComponent("Hello Norcha Print! Reference: ${r.code}")}'),
            mode: LaunchMode.externalApplication,
          ),
        ),
      ],
    );
  }

  static String _fmtDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final l = d.toLocal();
    return '${l.day} ${months[l.month - 1]} ${l.year}';
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(label, style: NorchaType.bodySmall.copyWith(fontSize: 13)),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: NorchaType.bodySmall.copyWith(
                fontSize: 13,
                color: NorchaPalette.ink,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool busy;

  const _PrimaryButton({required this.label, this.onTap, this.busy = false});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: onTap == null ? NorchaPalette.inkFaint : NorchaPalette.pine,
      borderRadius: BorderRadius.circular(NorchaShape.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(NorchaShape.sm),
        child: Container(
          height: 52,
          alignment: Alignment.center,
          child: busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: NorchaPalette.card),
                )
              : Text(
                  label,
                  style: NorchaType.body.copyWith(
                    color: NorchaPalette.card,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }
}
