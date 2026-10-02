// Norcha Print — Studio.
//
// The page a customer opens when they are standing outside looking for a sign,
// or when they want to talk to a person. It answers: where, when, how to reach
// us, and — the question this project keeps circling — what actually happens to
// my photos.
//
// That last section is not filler. A print shop asking for family photographs
// owes a plain answer about retention, and putting it on a page a customer can
// read at leisure is how the shop earns the trust the upload flow needs.

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/delivery.dart';
import '../../core/holidays.dart';
import '../../core/lang.dart';
import '../../core/pricing.dart';
import '../../theme/app_theme.dart';
import '../../theme/ghost_numerals.dart';
import '../../theme/theme_controller.dart';
import '../../widgets/cloth_surface.dart';
import '../../widgets/ethiopian.dart';
import '../../widgets/page_scaffold.dart';
import '../shell/app_shell.dart';

class AboutPage extends StatelessWidget {
  final ThemeController themes;
  final LangController langs;
  const AboutPage({super.key, required this.themes, required this.langs});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final occasion = NorchaHolidays.current(now);
    final ready = NorchaDelivery.assess(now, null, 2);

    return PageScaffold(
      chapter: 5,
      eyebrowKey: 'studio.eyebrow',
      titleKey: 'studio.title',
      ghostStyle: GhostStyle.outline,
      telafi: true,
      trailing: HeaderControls(themes: themes, langs: langs),
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: _OpenCard(),
        ),
        const SizedBox(height: 12),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: _ReachCard(),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: _TimingCard(ready: ready, occasion: occasion),
        ),
        const SizedBox(height: 12),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: _PhotoPrivacyCard(),
        ),
        const SizedBox(height: 26),
        const Center(child: _Monogram()),
      ],
    );
  }
}

/// The ኖ mark, set in the Amharic face — the same character as the launcher icon.
class _Monogram extends StatelessWidget {
  const _Monogram();

  @override
  Widget build(BuildContext context) {
    final c = NorchaColors.of(context);
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: c.card,
            shape: BoxShape.circle,
            border: Border.all(color: Brand.gold, width: 1),
          ),
          child: Text(
            '\u1296', // ኖ
            style: TextStyle(
              fontFamily: NorchaTypeFace.amharic,
              fontSize: 26,
              height: 1.1,
              color: Brand.action(c),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text('${Shop.name} · v0.3', style: NorchaType.bodySmall(c).copyWith(fontSize: 12)),
      ],
    );
  }
}

class _OpenCard extends StatelessWidget {
  const _OpenCard();

  @override
  Widget build(BuildContext context) {
    final c = NorchaColors.of(context);
    final lang = LangController.of(context).lang;
    return ClothSurface(
      accent: Brand.action(c),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(L.t('studio.findUs', lang), style: NorchaType.sectionLabel(c)),
          const SizedBox(height: 12),
          _Line(icon: Icons.place_outlined, text: Shop.city),
          const SizedBox(height: 4),
          _Line(icon: Icons.schedule_outlined, text: Shop.hours),
          const SizedBox(height: 4),
          _Line(
            icon: Icons.timer_outlined,
            text: '${L.t('studio.cutoff', lang)} ${Shop.cutoffHour}:00',
          ),
          const SizedBox(height: 16),
          _Action(
            label: L.t('studio.maps', lang),
            icon: Icons.map_outlined,
            onTap: () => launchUrl(
              Uri.parse('https://www.google.com/maps/search/?api=1&query='
                  'Norcha+Print+Bole+Addis+Ababa'),
              mode: LaunchMode.externalApplication,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReachCard extends StatelessWidget {
  const _ReachCard();

  @override
  Widget build(BuildContext context) {
    final c = NorchaColors.of(context);
    final lang = LangController.of(context).lang;
    return ClothSurface(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(L.t('studio.talk', lang), style: NorchaType.sectionLabel(c)),
          const SizedBox(height: 12),
          SelectableText(Shop.phone,
              style: NorchaType.title(c).copyWith(fontSize: 21)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _Action(
                  label: L.t('studio.whatsapp', lang),
                  icon: Icons.chat_outlined,
                  filled: true,
                  onTap: () => launchUrl(Uri.parse('https://wa.me/${Shop.wa}'),
                      mode: LaunchMode.externalApplication),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Action(
                  label: L.t('studio.call', lang),
                  icon: Icons.call_outlined,
                  filled: false,
                  onTap: () => launchUrl(Uri.parse('tel:${Shop.wa}'),
                      mode: LaunchMode.externalApplication),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// What the app actually computes, shown with its reasoning. Same engine the
/// quote screen uses, so the customer can see WHY a date is what it is.
class _TimingCard extends StatelessWidget {
  final DeliveryAssessment ready;
  final Occasion? occasion;

  const _TimingCard({required this.ready, required this.occasion});

  @override
  Widget build(BuildContext context) {
    final c = NorchaColors.of(context);
    final lang = LangController.of(context).lang;
    return ClothSurface(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(L.t('studio.howLong', lang), style: NorchaType.sectionLabel(c)),
          const SizedBox(height: 12),
          Text(NorchaDelivery.readyPhrase(ready, 'en'),
              style: NorchaType.title(c).copyWith(fontSize: 20)),
          const SizedBox(height: 8),
          Text(
            L.t('studio.timingNote', lang),
            style: NorchaType.bodySmall(c).copyWith(fontSize: 13),
          ),
          if (occasion != null) ...[
            const SizedBox(height: 16),
            Divider(color: c.line, height: 1),
            const SizedBox(height: 14),
            Text(
              '${occasion!.name('en')} is in ${occasion!.days} days. '
              'Last day to order is ${NorchaDelivery.fmt(occasion!.orderBy, 'en')}.',
              style: NorchaType.bodySmall(c).copyWith(fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }
}

/// 🔴 The retention promise, stated where a customer can read it calmly.
class _PhotoPrivacyCard extends StatelessWidget {
  const _PhotoPrivacyCard();

  @override
  Widget build(BuildContext context) {
    final c = NorchaColors.of(context);
    final lang = LangController.of(context).lang;
    return ClothSurface(
      accent: Brand.gold,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lock_outline_rounded, size: 17, color: Brand.gold),
              const SizedBox(width: 9),
              Text(L.t('studio.yourPhotos', lang), style: NorchaType.sectionLabel(c)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            L.t('studio.retention', lang),
            style: NorchaType.bodySmall(c).copyWith(fontSize: 13.5, color: c.ink),
          ),
          const SizedBox(height: 12),
          Text(
            L.t('studio.privacy', lang),
            style: NorchaType.bodySmall(c).copyWith(fontSize: 12.5),
          ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Line({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final c = NorchaColors.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: c.inkFaint),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text,
              style: NorchaType.bodySmall(c).copyWith(fontSize: 14, color: c.ink)),
        ),
      ],
    );
  }
}

class _Action extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;

  const _Action({
    required this.label,
    required this.icon,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = NorchaColors.of(context);
    final fg = filled ? Brand.onAction(c) : Brand.action(c);

    return Material(
      color: filled ? Brand.action(c) : Colors.transparent,
      borderRadius: BorderRadius.circular(Corners.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Corners.sm),
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Corners.sm),
            border: filled ? null : Border.all(color: c.line),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: fg),
              const SizedBox(width: 7),
              Text(label,
                  style: NorchaType.bodySmall(c).copyWith(
                      color: fg, fontWeight: FontWeight.w600, fontSize: 13.5)),
            ],
          ),
        ),
      ),
    );
  }
}
