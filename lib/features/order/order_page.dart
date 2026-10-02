// Norcha Print — Order lookup. "Did my photos arrive?"
//
// THE HONEST VERSION
// This does not pretend the shop has a live status feed. It answers one real
// question — what did you receive, and when — from the records the uploader
// wrote. A person at the studio still confirms sizes and price.
//
// 🔴 THE PRIVACY RULE, CARRIED INTO THE UI
// The endpoint returns ONE indistinguishable answer for unknown code, wrong
// phone and unreadable record, so it can never confirm to a stranger whether an
// order exists. This screen must not undo that by guessing which field was
// wrong. One error message for a 404, naming both fields, never the guilty one.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/lang.dart';
import '../../core/pricing.dart';
import '../../services/norcha_api.dart';
import '../../theme/app_theme.dart';
import '../../theme/theme_controller.dart';
import '../../widgets/cloth_surface.dart';
import '../../widgets/page_scaffold.dart';
import '../shell/app_shell.dart';
import '../../theme/ghost_numerals.dart';
import '../../widgets/ethiopian.dart';

class OrderPage extends StatefulWidget {
  final ThemeController themes;
  final LangController langs;
  const OrderPage({super.key, required this.themes, required this.langs});

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
    if (r.ok) HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    final c = NorchaColors.of(context);
    final lang = LangController.of(context).lang;

    return PageScaffold(
      chapter: 3,
      eyebrowKey: 'order.eyebrow',
      titleKey: 'order.title',
      ghostStyle: GhostStyle.outline,
      ghostLeft: true,
      trailing: HeaderControls(themes: widget.themes, langs: widget.langs),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                L.t('order.blurb', lang),
                style: NorchaType.bodySmall(c).copyWith(
                  fontFamily: lang.isAmharic
                      ? NorchaTypeFace.amharic
                      : NorchaTypeFace.body,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 20),
              _Field(
                controller: _code,
                label: L.t('order.ref', lang),
                hint: 'NOR-ABC123',
                caps: TextCapitalization.characters,
                formatters: [
                  // The server's alphabet: no 0/O/1/I/L, so a code can be read
                  // down a phone line without ambiguity.
                  FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9\-]')),
                  LengthLimitingTextInputFormatter(10),
                ],
              ),
              const SizedBox(height: 14),
              _Field(
                controller: _phone,
                label: L.t('order.phone', lang),
                hint: '09•• ••• •••',
                keyboard: TextInputType.phone,
                formatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9+\- ]')),
                ],
              ),
              const SizedBox(height: 22),
              _PrimaryButton(
                label: _busy
                    ? L.t('order.checking', lang)
                    : L.t('order.check', lang),
                busy: _busy,
                onTap: _busy ? null : _check,
              ),
              const SizedBox(height: 18),
              if (_result != null)
                // Animated in rather than appearing: the result is the whole
                // point of the screen and a hard cut makes it feel like a page
                // reload rather than an answer.
                AnimatedSwitcher(
                  duration: Motion.medium,
                  switchInCurve: Curves.easeOutCubic,
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.04),
                        end: Offset.zero,
                      ).animate(anim),
                      child: child,
                    ),
                  ),
                  child: _ResultBlock(
                    key: ValueKey('${_result!.status}-${_result!.record?.code}'),
                    result: _result!,
                    onCheckAnother: () => setState(() {
                      _result = null;
                      _code.clear();
                      _phone.clear();
                    }),
                  ),
                ),
            ],
          ),
        ),
      ],
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
    final c = NorchaColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: NorchaType.sectionLabel(c)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboard,
          textCapitalization: caps,
          inputFormatters: formatters,
          style: NorchaType.body(c).copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
          cursorColor: Brand.action(c),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: NorchaType.body(c).copyWith(color: c.inkFaint),
            filled: true,
            fillColor: c.card,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Corners.sm),
              borderSide: BorderSide(color: c.line),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Corners.sm),
              borderSide: BorderSide(color: Brand.action(c), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

class _ResultBlock extends StatelessWidget {
  final LookupResult result;
  final VoidCallback onCheckAnother;

  const _ResultBlock({super.key, required this.result, required this.onCheckAnother});

  @override
  Widget build(BuildContext context) {
    final c = NorchaColors.of(context);

    if (!result.ok) {
      return ClothSurface(
        accent: Brand.warn,
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline, size: 19, color: Brand.warn),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                result.message?.call('en') ??
                    'We could not check that. Please try again.',
                style: NorchaType.bodySmall(c)
                    .copyWith(fontSize: 14, color: c.ink),
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
          accent: Brand.action(c),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 34, height: 34,
                    decoration: BoxDecoration(
                      color: Brand.action(c).withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.check_rounded,
                        size: 18, color: Brand.action(c)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(L.t('order.found', lang),
                        style: NorchaType.title(c).copyWith(fontSize: 18)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Selectable: the customer will paste this into WhatsApp, so it
              // must be copyable in one gesture.
              SelectableText(
                r.code,
                style: NorchaType.title(c).copyWith(
                  fontSize: 26, letterSpacing: 1.5, color: Brand.action(c),
                ),
              ),
              const SizedBox(height: 16),
              Divider(color: c.line, height: 1),
              const SizedBox(height: 14),
              _Row(L.t('order.received', lang), '${r.files}'),
              if (r.received != null) _Row(L.t('order.arrived', lang), _fmt(r.received!)),
              if (r.requestedSummary != '—')
                _Row(L.t('order.asked', lang), r.requestedSummary),
              if (r.deleteAfter != null)
                _Row(L.t('order.deleted', lang), _fmt(r.deleteAfter!)),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: c.groundDeep,
                  borderRadius: BorderRadius.circular(Corners.xs),
                ),
                child: Text(
                  r.stageNote.isEmpty
                      ? 'The studio has your photos. A person confirms sizes '
                          'and price before printing.'
                      : r.stageNote,
                  style: NorchaType.bodySmall(c).copyWith(fontSize: 12.5),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _PrimaryButton(
          label: L.t('order.whatsapp', lang),
          // Built outside the widget tree: a multi-line interpolation with a
          // nested call is hard to read and easy to mis-parse. One variable
          // costs nothing and makes the intent obvious.
          onTap: () => launchUrl(
            Uri.parse(_waLink(r.code)),
            mode: LaunchMode.externalApplication,
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: TextButton(
            onPressed: onCheckAnother,
            child: Text(L.t('order.another', lang),
                style: NorchaType.bodySmall(c)
                    .copyWith(decoration: TextDecoration.underline)),
          ),
        ),
      ],
    );
  }

  /// The WhatsApp handoff with the reference pre-filled, so the code lands in
  /// the same conversation as the photos.
  static String _waLink(String code) {
    final text = Uri.encodeComponent('Hello Norcha Print! Reference: $code');
    return 'https://wa.me/${Shop.wa}?text=$text';
  }

  static String _fmt(DateTime d) {
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final l = d.toLocal();
    return '${l.day} ${m[l.month - 1]} ${l.year}';
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final c = NorchaColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(label, style: NorchaType.bodySmall(c).copyWith(fontSize: 13)),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: NorchaType.bodySmall(c).copyWith(
                fontSize: 13, color: c.ink, fontWeight: FontWeight.w600,
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
    final c = NorchaColors.of(context);
    return Pressable(
      onTap: onTap,
      child: Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: onTap == null ? c.inkFaint : Brand.action(c),
          borderRadius: BorderRadius.circular(Corners.sm),
        ),
        child: busy
            ? SizedBox(
                width: 18, height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Brand.onAction(c)),
              )
            : Text(
                label,
                style: NorchaType.body(c).copyWith(
                  color: Brand.onAction(c),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
