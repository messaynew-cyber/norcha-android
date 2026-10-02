// Norcha Print — Studio.
//
// The page a customer opens when they are standing outside looking for a sign,
// or when they want to talk to a person. It answers: where, when, how to reach
// us, and — the question this whole project keeps circling — what actually
// happens to my photos.
//
// That last section is not filler. A print shop asking for family photographs
// owes a plain answer about retention, and putting it on a page the customer
// can read at leisure is how the shop earns the trust the upload flow needs.

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/delivery.dart';
import '../../core/holidays.dart';
import '../../core/pricing.dart';
import '../../theme/netela.dart';
import '../shell/app_shell.dart';
import '../../theme/norcha_theme.dart';
import '../../widgets/cloth_surface.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final occasion = NorchaHolidays.current(now);
    final ready = NorchaDelivery.assess(now, null, 2);

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          const NorchaHeader(
            eyebrow: 'The studio',
            title: 'Norcha Print,\nBole.',
            amharic: 'ኖርቻ ፕሪንት · ቦሌ',
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: _OpenCard(),
          ),

          const SizedBox(height: 14),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: _ReachCard(),
          ),

          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _TimingCard(ready: ready, occasion: occasion),
          ),

          const SizedBox(height: 14),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: _PhotoPrivacyCard(),
          ),

          const SizedBox(height: 24),
          Center(
            child: Column(
              children: [
                // The monogram, as a mark rather than an image — the same ኖ that
                // is the launcher icon, set in the Amharic face.
                Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: NorchaPalette.card,
                    shape: BoxShape.circle,
                    border: Border.all(color: NorchaPalette.gold, width: 1),
                  ),
                  child: Text(
                    'ኖ',
                    style: TextStyle(
                      fontFamily: NorchaType.amharicFamily,
                      fontSize: 24,
                      height: 1.1,
                      color: NorchaPalette.pine,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text('${Shop.name} · v0.2',
                    style: NorchaType.bodySmall.copyWith(fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _OpenCard extends StatelessWidget {
  const _OpenCard();

  @override
  Widget build(BuildContext context) {
    return ClothSurface(
      accent: NorchaPalette.pine,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('FIND US', style: NorchaType.sectionLabel),
          const SizedBox(height: 12),
          _Line(icon: Icons.place_outlined, text: Shop.city),
          const SizedBox(height: 4),
          _Line(icon: Icons.schedule_outlined, text: Shop.hours),
          const SizedBox(height: 4),
          _Line(
            icon: Icons.timer_outlined,
            text: 'Same-day cut-off ${Shop.cutoffHour}:00',
          ),
          const SizedBox(height: 16),
          _Action(
            label: 'Open in Maps',
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
    return ClothSurface(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('TALK TO A PERSON', style: NorchaType.sectionLabel),
          const SizedBox(height: 12),
          SelectableText(
            Shop.phone,
            style: NorchaType.title.copyWith(fontSize: 21),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _Action(
                  label: 'WhatsApp',
                  icon: Icons.chat_outlined,
                  filled: true,
                  onTap: () => launchUrl(
                    Uri.parse('https://wa.me/${Shop.wa}'),
                    mode: LaunchMode.externalApplication,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Action(
                  label: 'Call',
                  icon: Icons.call_outlined,
                  onTap: () => launchUrl(
                    Uri.parse('tel:${Shop.wa}'),
                    mode: LaunchMode.externalApplication,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// What the app actually computes, shown with its reasoning. This is the same
/// engine the quote screen uses — showing it here means the customer can see
/// WHY a date is what it is, rather than trusting a black box.
class _TimingCard extends StatelessWidget {
  final DeliveryAssessment ready;
  final Occasion? occasion;

  const _TimingCard({required this.ready, required this.occasion});

  @override
  Widget build(BuildContext context) {
    return ClothSurface(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('HOW LONG IT TAKES', style: NorchaType.sectionLabel),
          const SizedBox(height: 12),
          Text(
            NorchaDelivery.readyPhrase(ready, 'en'),
            style: NorchaType.title.copyWith(fontSize: 20),
          ),
          const SizedBox(height: 8),
          Text(
            'A photo book takes two production days; prints and canvas take '
            'less. Sundays the shop is shut, so they are not counted.',
            style: NorchaType.bodySmall.copyWith(fontSize: 13),
          ),
          if (occasion != null) ...[
            const SizedBox(height: 16),
            const Divider(color: NorchaPalette.line, height: 1),
            const SizedBox(height: 14),
            Text(
              '${occasion!.name('en')} is in ${occasion!.days} days. '
              'Last day to order is ${NorchaDelivery.fmt(occasion!.orderBy, 'en')}.',
              style: NorchaType.bodySmall.copyWith(fontSize: 13),
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
    return ClothSurface(
      accent: NorchaPalette.gold,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lock_outline_rounded,
                  size: 17, color: NorchaPalette.gold),
              SizedBox(width: 9),
              Text('YOUR PHOTOS', style: NorchaType.sectionLabel),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'We keep your photos for 30 days so we can print them, then we '
            'delete them. We do not publish them, and we do not sell them.',
            style: NorchaType.bodySmall.copyWith(
                fontSize: 13.5, color: NorchaPalette.ink),
          ),
          const SizedBox(height: 12),
          Text(
            'Order lookup needs both your reference AND the phone number you '
            'ordered with. One without the other gets no answer — so nobody can '
            'use it to check whether an order exists.',
            style: NorchaType.bodySmall.copyWith(fontSize: 12.5),
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: NorchaPalette.inkFaint),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text,
              style: NorchaType.bodySmall.copyWith(
                  fontSize: 14, color: NorchaPalette.ink)),
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
    final fg = filled ? NorchaPalette.card : NorchaPalette.pine;

    return Material(
      color: filled ? NorchaPalette.pine : Colors.transparent,
      borderRadius: BorderRadius.circular(NorchaShape.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(NorchaShape.sm),
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(NorchaShape.sm),
            border: filled
                ? null
                : Border.all(color: NorchaPalette.pine.withOpacity(0.35)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: fg),
              const SizedBox(width: 7),
              Text(label,
                  style: NorchaType.bodySmall.copyWith(
                      color: fg,
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5)),
            ],
          ),
        ),
      ),
    );
  }
}
