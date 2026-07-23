import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:parentpeak/logic/parent_coin_service.dart';
import 'package:parentpeak/logic/auth_service.dart';

/// Eltern-Netzwerk — Einladen, Verbinden, Belohnt werden.
///
/// Features:
/// - ParentCoin Dashboard (Fortschritt zu Gratis-Premium)
/// - Einladungs-Tools (Link, QR-Code, Share)
/// - Eltern-Kreise (themenbasiert, altersbasiert)
/// - Nachrichten (kommt Phase 3)
class ElternNetzwerkScreen extends StatefulWidget {
  const ElternNetzwerkScreen({super.key});

  @override
  State<ElternNetzwerkScreen> createState() => _ElternNetzwerkScreenState();
}

class _ElternNetzwerkScreenState extends State<ElternNetzwerkScreen> {
  @override
  void initState() {
    super.initState();
    ParentCoinService.instance.initialize();
    ParentCoinService.instance.addListener(_refresh);
  }

  @override
  void dispose() {
    ParentCoinService.instance.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final coins = ParentCoinService.instance;

    return Scaffold(
      appBar: AppBar(title: const Text('Eltern-Netzwerk'), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ─── ParentCoin Dashboard ──────────────────────
          _buildCoinCard(theme, coins),
          const SizedBox(height: 20),

          // ─── Einladen ─────────────────────────────────
          Text('Freunde einladen',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('Fuer jede Registrierung bekommst du 1 ParentCoin.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 14),
          _buildInviteActions(theme, coins),
          const SizedBox(height: 24),

          // ─── Eltern-Kreise ────────────────────────────
          Text('Eltern-Kreise',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('Tausche dich mit Eltern in aehnlicher Situation aus.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 14),
          _buildCircles(theme),
          const SizedBox(height: 24),

          // ─── Coin-Verlauf ─────────────────────────────
          if (coins.history.isNotEmpty) ...[
            Text('Verlauf',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            ...coins.history
                .take(5)
                .map((tx) => _buildTransactionRow(theme, tx)),
          ],
        ]),
      ),
    );
  }

  // ─── ParentCoin Card ────────────────────────────────────────────────────────

  Widget _buildCoinCard(ThemeData theme, ParentCoinService coins) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          const Color(0xFF0EA5A4),
          const Color(0xFF0EA5A4).withValues(alpha: 0.8)
        ], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF0EA5A4).withValues(alpha: 0.2),
              blurRadius: 16,
              offset: const Offset(0, 6))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14)),
              child: const Center(
                  child: Text('\u{1FA99}', style: TextStyle(fontSize: 24)))),
          const SizedBox(width: 14),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('${coins.balance} ParentCoins',
                    style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white, fontWeight: FontWeight.w800)),
                Text('${coins.coinsUntilFreePremium} bis Gratis-Premium',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: Colors.white.withValues(alpha: 0.8))),
              ])),
          if (coins.hasCommunityBadge)
            Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text('Community',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withValues(alpha: 0.9)))
                ])),
        ]),
        const SizedBox(height: 16),
        // Progress bar
        ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
                value: coins.progressToFreePremium.clamp(0, 1),
                minHeight: 8,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white))),
        const SizedBox(height: 8),
        Row(children: [
          Text('${coins.successfulInvites} Einladungen erfolgreich',
              style: TextStyle(
                  fontSize: 11, color: Colors.white.withValues(alpha: 0.75))),
          const Spacer(),
          Text('${coins.balance}/${ParentCoinService.coinsForFreePremium}',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.9))),
        ]),
        if (coins.balance >= ParentCoinService.coinsForFreePremium) ...[
          const SizedBox(height: 12),
          SizedBox(
              width: double.infinity,
              child: FilledButton(
                  onPressed: () async {
                    final ok = await coins.redeemForPremium();
                    if (ok && mounted)
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content:
                              Text('Premium fuer 1 Monat freigeschaltet!')));
                  },
                  style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF0EA5A4),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  child: const Text('Jetzt Premium einloesen'))),
        ],
      ]),
    );
  }

  // ─── Einladungs-Aktionen ────────────────────────────────────────────────────

  Widget _buildInviteActions(ThemeData theme, ParentCoinService coins) {
    return Column(children: [
      // Link teilen
      GestureDetector(
        onTap: () async {
          HapticFeedback.lightImpact();
          await Share.share(coins.getInviteMessage());
        },
        child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: theme.colorScheme.outlineVariant
                        .withValues(alpha: 0.5))),
            child: Row(children: [
              Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                      color: const Color(0xFF0EA5A4).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.share_rounded,
                      color: Color(0xFF0EA5A4), size: 20)),
              const SizedBox(width: 14),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('Einladung teilen',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    Text('Per WhatsApp, SMS oder E-Mail',
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                  ])),
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 16, color: theme.colorScheme.outline),
            ])),
      ),
      const SizedBox(height: 10),
      // QR-Code
      GestureDetector(
        onTap: () => _showQRCode(theme, coins),
        child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: theme.colorScheme.outlineVariant
                        .withValues(alpha: 0.5))),
            child: Row(children: [
              Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.qr_code_rounded,
                      color: Color(0xFF8B5CF6), size: 20)),
              const SizedBox(width: 14),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('QR-Code zeigen',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    Text('Am Spielplatz oder Elternabend scannen',
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                  ])),
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 16, color: theme.colorScheme.outline),
            ])),
      ),
      const SizedBox(height: 10),
      // Link kopieren
      GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          Clipboard.setData(ClipboardData(text: coins.getInviteLink()));
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Link kopiert!'),
              behavior: SnackBarBehavior.floating));
        },
        child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: theme.colorScheme.outlineVariant
                        .withValues(alpha: 0.5))),
            child: Row(children: [
              Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.link_rounded,
                      color: Color(0xFF2563EB), size: 20)),
              const SizedBox(width: 14),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('Link kopieren',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    Text(coins.getInviteLink(),
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant),
                        overflow: TextOverflow.ellipsis),
                  ])),
              Icon(Icons.content_copy_rounded,
                  size: 18, color: theme.colorScheme.outline),
            ])),
      ),
    ]);
  }

  void _showQRCode(ThemeData theme, ParentCoinService coins) {
    showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (ctx) => Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(24))),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text('Dein Einladungs-Code',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text('Andere Eltern scannen diesen Code',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(height: 24),
                Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16)),
                    child: QrImageView(
                        data: coins.getInviteLink(),
                        version: QrVersions.auto,
                        size: 200)),
                const SizedBox(height: 16),
                Text(coins.referralCode,
                    style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800, letterSpacing: 2)),
                const SizedBox(height: 20),
                SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Fertig'))),
              ]),
            ));
  }

  // ─── Eltern-Kreise ──────────────────────────────────────────────────────────

  Widget _buildCircles(ThemeData theme) {
    final circles = [
      _Circle(
          emoji: '\u{1F476}',
          title: 'Baby & Kleinkind',
          subtitle: 'Eltern mit 0-3 Jahren',
          members: 24,
          color: const Color(0xFF0EA5E9)),
      _Circle(
          emoji: '\u{1F393}',
          title: 'Kita & Vorschule',
          subtitle: 'Eltern mit 3-6 Jahren',
          members: 18,
          color: const Color(0xFF16A34A)),
      _Circle(
          emoji: '\u{1F4DA}',
          title: 'Schulkind',
          subtitle: 'Eltern mit 6-12 Jahren',
          members: 12,
          color: const Color(0xFFF59E0B)),
      _Circle(
          emoji: '\u{1F9D1}',
          title: 'Teenager',
          subtitle: 'Eltern mit 12-18 Jahren',
          members: 8,
          color: const Color(0xFF8B5CF6)),
      _Circle(
          emoji: '\u{1F49C}',
          title: 'Alleinerziehend',
          subtitle: 'Fuer Alleinerziehende',
          members: 15,
          color: const Color(0xFFEC4899)),
      _Circle(
          emoji: '\u{1F30D}',
          title: 'Mehrsprachig',
          subtitle: 'Familien mit mehreren Sprachen',
          members: 9,
          color: const Color(0xFF0EA5A4)),
    ];

    return Column(
        children: circles
            .map((c) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GestureDetector(
                    onTap: () => _showCircleComingSoon(theme, c),
                    child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: c.color.withValues(alpha: 0.12))),
                        child: Row(children: [
                          Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                  color: c.color.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12)),
                              child: Center(
                                  child: Text(c.emoji,
                                      style: const TextStyle(fontSize: 20)))),
                          const SizedBox(width: 12),
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Text(c.title,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w700)),
                                Text(c.subtitle,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme
                                            .colorScheme.onSurfaceVariant)),
                              ])),
                          Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                  color: c.color.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(8)),
                              child: Text('${c.members}',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: c.color))),
                          const SizedBox(width: 8),
                          Icon(Icons.arrow_forward_ios_rounded,
                              size: 14, color: theme.colorScheme.outline),
                        ])),
                  ),
                ))
            .toList());
  }

  void _showCircleComingSoon(ThemeData theme, _Circle circle) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('${circle.title} — Nachrichten kommen bald!'),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  // ─── Transaction Row ────────────────────────────────────────────────────────

  Widget _buildTransactionRow(ThemeData theme, CoinTransaction tx) {
    final isEarned = tx.type == CoinTransactionType.earned ||
        tx.type == CoinTransactionType.bonus;
    return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            Icon(
                isEarned
                    ? Icons.add_circle_rounded
                    : Icons.remove_circle_rounded,
                size: 20,
                color: isEarned
                    ? const Color(0xFF16A34A)
                    : const Color(0xFFEF4444)),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(tx.reason,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  Text('${tx.date.day}.${tx.date.month}.${tx.date.year}',
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: theme.colorScheme.outline)),
                ])),
            Text('${isEarned ? "+" : "-"}${tx.amount}',
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: isEarned
                        ? const Color(0xFF16A34A)
                        : const Color(0xFFEF4444))),
          ]),
        ));
  }
}

class _Circle {
  final String emoji;
  final String title;
  final String subtitle;
  final int members;
  final Color color;
  const _Circle(
      {required this.emoji,
      required this.title,
      required this.subtitle,
      required this.members,
      required this.color});
}
