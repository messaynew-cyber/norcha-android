// Norcha Print — Upload.
//
// 🔴 THE RULE THIS SCREEN OBEYS
// It asks the server whether uploads are switched on BEFORE it offers them.
// If GET /api/upload says 503, the entry point stays HIDDEN and the page
// explains the WhatsApp alternative instead. Under no circumstance does it show
// a working upload box that cannot deliver — a customer who believes their
// photos are in and finds out they are not has lost something we cannot give
// back. That rule is from the website and it is the right one.
//
// And when an upload FAILS: the photos are still on the customer's phone. Say
// that first, in those words. It is the only thing they are actually worried
// about.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/pricing.dart';
import '../../services/norcha_api.dart';
import '../../services/photo_upload.dart';
import '../../theme/app_theme.dart';
import '../../theme/ghost_numerals.dart';
import '../../theme/theme_controller.dart';
import '../../widgets/cloth_surface.dart';
import '../../widgets/loading_mark.dart';
import '../../widgets/page_scaffold.dart';
import '../shell/app_shell.dart';

class UploadPage extends StatefulWidget {
  final ThemeController themes;
  const UploadPage({super.key, required this.themes});

  @override
  State<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _note = TextEditingController();

  UploadProbe? _probe;
  bool _probing = true;

  final List<File> _photos = [];
  String _family = 'prints';
  String? _sizeKey;

  bool _sending = false;
  double _progress = 0;
  UploadSuccess? _success;
  UploadFailure? _failure;

  @override
  void initState() {
    super.initState();
    _probeServer();
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _probeServer() async {
    final p = await NorchaApi.probeUpload();
    if (!mounted) return;
    setState(() {
      _probe = p;
      _probing = false;
    });
  }

  Future<void> _pick() async {
    try {
      final picker = ImagePicker();
      final files = await picker.pickMultiImage();
      if (files.isEmpty) return;
      if (!mounted) return;
      setState(() {
        _photos
          ..clear()
          ..addAll(files.map((x) => File(x.path)));
        _failure = null;
      });
    } catch (_) {
      // A cancelled or denied picker is not an error worth shouting about.
    }
  }

  Future<void> _send() async {
    final req = UploadRequest(
      photos: _photos,
      name: _name.text,
      phone: _phone.text,
      note: _note.text,
      product: _family,
      size: _sizeKey ?? '',
      qty: '',
    );

    setState(() {
      _sending = true;
      _progress = 0;
      _failure = null;
    });

    try {
      final res = await PhotoUpload.send(
        req,
        onProgress: (p) {
          if (mounted) setState(() => _progress = p);
        },
      );
      if (!mounted) return;
      setState(() {
        _sending = false;
        _success = res;
      });
    } on UploadFailure catch (e) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _failure = e;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = NorchaColors.of(context);

    return PageScaffold(
      chapter: 4,
      eyebrow: 'Send photos',
      title: 'Upload your\noriginals.',
      amharic: 'ፎቶዎችዎን ይላኩ',
      ghostStyle: GhostStyle.soft,
      trailing: ThemeButton(themes: widget.themes),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: _probing
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(
                    child: LoadingMark(size: 74, label: 'Checking\u2026'),
                  ),
                )
              : _probe?.configured != true
                  ? const _UploadOffCard()
                  : _success != null
                      ? _SuccessCard(success: _success!)
                      : _form(),
        ),
      ],
    );
  }

  Widget _form() {
    final product = NorchaData.products[_family]!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Same originals, no compression. You get a reference number you can '
          'read down a phone line.',
          style: NorchaType.body(c)Small(c).copyWith(fontSize: 14),
        ),
        const SizedBox(height: 20),

        // Photo picker
        ClothSurface(
          onTap: _photos.isEmpty ? _pick : null,
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              Icon(
                _photos.isEmpty
                    ? Icons.add_photo_alternate_outlined
                    : Icons.collections_rounded,
                size: 30,
                color: Brand.action(c),
              ),
              const SizedBox(height: 10),
              Text(
                _photos.isEmpty
                    ? 'Choose photos'
                    : '${_photos.length} selected',
                style: NorchaType.title(c).copyWith(fontSize: 17),
              ),
              const SizedBox(height: 4),
              Text(
                _photos.isEmpty
                    ? 'Up to ${PhotoUpload.maxFiles} · max '
                        '${PhotoUpload.maxPerFileMb} MB each'
                    : 'Tap to choose again',
                style: NorchaType.body(c)Small(c).copyWith(fontSize: 12.5),
              ),
            ],
          ),
        ),

        if (_photos.isNotEmpty) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 66,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _photos.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) => ClipRRect(
                borderRadius: BorderRadius.circular(Radius.xs),
                child: Image.file(
                  _photos[i],
                  width: 66,
                  height: 66,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 66,
                    height: 66,
                    color: c.groundDeep,
                    child: const Icon(Icons.broken_image_outlined,
                        size: 18, color: c.inkFaint),
                  ),
                ),
              ),
            ),
          ),
        ],

        const SizedBox(height: 20),
        const Text('WHAT IS IT FOR?', style: NorchaType.sectionLabel(c)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final f in NorchaData.products.keys)
              _Chip(
                label: NorchaData.products[f]!.label.en,
                accent: Accent.forFamily(f),
                selected: _family == f,
                onTap: () => setState(() {
                  _family = f;
                  _sizeKey = null;
                }),
              ),
          ],
        ),

        const SizedBox(height: 18),
        const Text('SIZE (OPTIONAL)', style: NorchaType.sectionLabel(c)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final s in product.sizes)
              _Chip(
                label: s.label,
                accent: Accent.forFamily(_family),
                selected: _sizeKey == s.key,
                onTap: () => setState(
                    () => _sizeKey = _sizeKey == s.key ? null : s.key),
              ),
          ],
        ),

        const SizedBox(height: 20),
        _TextInput(controller: _name, label: 'YOUR NAME', hint: 'Abebe B.'),
        const SizedBox(height: 14),
        _TextInput(
          controller: _phone,
          label: 'PHONE',
          hint: '09•• ••• •••',
          keyboard: TextInputType.phone,
        ),
        const SizedBox(height: 14),
        _TextInput(
          controller: _note,
          label: 'ANYTHING WE SHOULD KNOW',
          hint: 'Optional',
          lines: 2,
        ),

        const SizedBox(height: 22),

        if (_failure != null) ...[
          ClothSurface(
            accent: Brand.warn,
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline,
                    size: 19, color: Brand.warn),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    _failure!.message.call('en'),
                    style: NorchaType.body(c)Small(c).copyWith(
                        fontSize: 13.5, color: c.ink),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],

        if (_sending) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: _progress,
              minHeight: 4,
              backgroundColor: c.groundDeep,
              valueColor:
                  const AlwaysStoppedAnimation(Brand.action(c)),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(_progress * 100).round()}% sent',
            style: NorchaType.body(c)Small(c).copyWith(fontSize: 12),
          ),
          const SizedBox(height: 14),
        ],

        _PrimaryButton(
          label: _sendLabel,
          busy: _sending,
          onTap: (_sending || _photos.isEmpty) ? null : _send,
        ),
        const SizedBox(height: 12),
        Text(
          'The chat still works and it always will — WhatsApp is right there '
          'if you would rather send them that way.',
          style: NorchaType.body(c)Small(c).copyWith(fontSize: 12),
        ),
      ],
    );
  }
}

/// Shown when the bucket is not bound. The feature is OFF, not broken, and the
/// copy says so — plus the door that does work.
class _UploadOffCard extends StatelessWidget {
  const _UploadOffCard();

  @override
  Widget build(BuildContext context) {
    final c = NorchaColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClothSurface(
          accent: Brand.warn,
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.cloud_off_outlined,
                      size: 20, color: Brand.warn),
                  SizedBox(width: 11),
                  Text('Upload is not switched on yet',
                      style: TextStyle(
                        fontFamily: NorchaType.body(c)Family,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: c.ink,
                      )),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Please send your photos on WhatsApp — it works right now, and '
                'you keep the chat.',
                style: NorchaType.body(c)Small(c).copyWith(fontSize: 13.5),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _PrimaryButton(
          label: 'Send on WhatsApp',
          onTap: () => launchUrl(
            Uri.parse('https://wa.me/${Shop.wa}'),
            mode: LaunchMode.externalApplication,
          ),
        ),
      ],
    );
  }
}

/// The reference the customer must keep. Big, copyable, and paired with the
/// WhatsApp handoff so the code lands in the same conversation as the photos.
class _SuccessCard extends StatelessWidget {
  final UploadSuccess success;
  const _SuccessCard({required this.success});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClothSurface(
          accent: Brand.action(c),
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Brand.action(c).withOpacity(0.10),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_rounded,
                        size: 19, color: Brand.action(c)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('${success.stored} photos received',
                        style: NorchaType.title(c).copyWith(fontSize: 18)),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Text('YOUR REFERENCE', style: NorchaType.sectionLabel(c)),
              const SizedBox(height: 8),
              SelectableText(
                success.code,
                style: NorchaType.title(c).copyWith(
                  fontSize: 28,
                  letterSpacing: 2,
                  color: Brand.action(c),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Keep this. A person at the studio still confirms sizes and '
                'price before printing — message us and we will confirm.',
                style: NorchaType.body(c)Small(c).copyWith(fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _PrimaryButton(
          label: 'Send the reference on WhatsApp',
          onTap: () => launchUrl(
            Uri.parse('https://wa.me/${Shop.wa}?text='
                '${Uri.encodeComponent("Hello Norcha Print! Reference: ${success.code}")}'),
            mode: LaunchMode.externalApplication,
          ),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Accent accent;
  final bool selected;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.accent,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = NorchaColors.of(context);
    return Material(
      color: selected ? accent.colour.withOpacity(0.10) : c.card,
      borderRadius: BorderRadius.circular(Radius.pill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Radius.pill),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Radius.pill),
            border: Border.all(
              color: selected ? accent.colour : c.line,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Text(
            label,
            style: NorchaType.body(c)Small(c).copyWith(
              fontSize: 13,
              color: selected ? accent.colour : c.inkSoft,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}

class _TextInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputType? keyboard;
  final int lines;

  const _TextInput({
    required this.controller,
    required this.label,
    required this.hint,
    this.keyboard,
    this.lines = 1,
  });

  @override
  Widget build(BuildContext context) {
    final c = NorchaColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: NorchaType.sectionLabel(c)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboard,
          maxLines: lines,
          style: NorchaType.body(c).copyWith(fontSize: 15),
          cursorColor: Brand.action(c),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: NorchaType.body(c).copyWith(color: c.inkFaint),
            filled: true,
            fillColor: c.card,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Radius.sm),
              borderSide: const BorderSide(color: c.line),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Radius.sm),
              borderSide: const BorderSide(color: Brand.action(c), width: 1.5),
            ),
          ),
        ),
      ],
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
    final c = NorchaColors.of(context);
    return Material(
      color: onTap == null ? c.inkFaint : Brand.action(c),
      borderRadius: BorderRadius.circular(Radius.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Radius.sm),
        child: Container(
          height: 52,
          alignment: Alignment.center,
          child: busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: c.card),
                )
              : Text(
                  label,
                  style: NorchaType.body(c).copyWith(
                    color: c.card,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }
}
