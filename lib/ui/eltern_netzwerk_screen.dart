import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:parentpeak/logic/parent_coin_service.dart';
import 'package:parentpeak/logic/auth_service.dart';
import 'package:parentpeak/logic/spielfreunde_backend_service.dart';
import 'package:parentpeak/models/family_profile_model.dart';

class ElternNetzwerkScreen extends StatefulWidget {
  const ElternNetzwerkScreen({super.key});
  @override
  State<ElternNetzwerkScreen> createState() => _ScreenState();
}

class _ScreenState extends State<ElternNetzwerkScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _backend = SpielfreundeBackendService();
  FamilyMatchProfile? _profile;
  WaitlistStatus _waitlist =
      const WaitlistStatus(total: 0, threshold: 20, remaining: 20, progress: 0);

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    ParentCoinService.instance.initialize();
    ParentCoinService.instance.addListener(_rebuild);
    _init();
  }

  @override
  void dispose() {
    _tabs.dispose();
    ParentCoinService.instance.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  Future<void> _init() async {
    final p = await FamilyMatchProfile.load();
    if (mounted) setState(() => _profile = p);
    if (p != null) {
      final w = await _backend.getWaitlistCount(p.district);
      if (mounted) setState(() => _waitlist = w);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Eltern-Netzwerk'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Einladen & Coins'),
            Tab(text: 'Spielfreunde')
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [_inviteTab(theme), _spielfreundeTab(theme)],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 1: EINLADEN & COINS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _inviteTab(ThemeData theme) {
    final coins = ParentCoinService.instance;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Coin Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFF0EA5A4), Color(0xFF06B6D4)]),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                  color: const Color(0xFF0EA5A4).withValues(alpha: 0.2),
                  blurRadius: 16,
                  offset: const Offset(0, 6))
            ],
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14)),
                  child: const Center(
                      child:
                          Text('\u{1FA99}', style: TextStyle(fontSize: 24)))),
              const SizedBox(width: 14),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('${coins.balance} ParentCoins',
                        style: theme.textTheme.titleLarge?.copyWith(
                            color: Colors.white, fontWeight: FontWeight.w800)),
                    Text('${coins.coinsUntilFreePremium} bis Gratis-Premium',
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.8))),
                  ])),
              if (coins.hasCommunityBadge)
                Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8)),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                      SizedBox(width: 4),
                      Text('Community',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white))
                    ])),
            ]),
            const SizedBox(height: 16),
            ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                    value: coins.progressToFreePremium.clamp(0, 1),
                    minHeight: 8,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.white))),
            const SizedBox(height: 8),
            Text('${coins.successfulInvites} Einladungen erfolgreich',
                style: TextStyle(
                    fontSize: 11, color: Colors.white.withValues(alpha: 0.75))),
            if (coins.balance >= ParentCoinService.coinsForFreePremium) ...[
              const SizedBox(height: 12),
              SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                      onPressed: () async {
                        await coins.redeemForPremium();
                      },
                      style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF0EA5A4),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                      child: const Text('Premium einloesen')))
            ],
          ]),
        ),
        const SizedBox(height: 20),
        Text('Freunde einladen',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text('Fuer jede Registrierung: 1 ParentCoin.',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 14),
        _inviteRow(theme, Icons.share_rounded, const Color(0xFF0EA5A4),
            'Einladung teilen', 'WhatsApp, SMS, E-Mail', () async {
          await Share.share(coins.getInviteMessage());
        }),
        const SizedBox(height: 10),
        _inviteRow(
            theme,
            Icons.qr_code_rounded,
            const Color(0xFF8B5CF6),
            'QR-Code zeigen',
            'Am Spielplatz scannen',
            () => _showQR(theme, coins)),
        const SizedBox(height: 10),
        _inviteRow(theme, Icons.link_rounded, const Color(0xFF2563EB),
            'Link kopieren', coins.getInviteLink(), () {
          Clipboard.setData(ClipboardData(text: coins.getInviteLink()));
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Link kopiert!')));
        }),
        if (coins.history.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text('Verlauf',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          ...coins.history.take(5).map((tx) {
            final e = tx.type != CoinTransactionType.spent;
            return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(12)),
                    child: Row(children: [
                      Icon(
                          e
                              ? Icons.add_circle_rounded
                              : Icons.remove_circle_rounded,
                          size: 18,
                          color: e
                              ? const Color(0xFF16A34A)
                              : const Color(0xFFEF4444)),
                      const SizedBox(width: 10),
                      Expanded(
                          child: Text(tx.reason,
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis)),
                      Text('${e ? "+" : "-"}${tx.amount}',
                          style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              color: e
                                  ? const Color(0xFF16A34A)
                                  : const Color(0xFFEF4444)))
                    ])));
          })
        ],
      ]),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 2: SPIELFREUNDE
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _spielfreundeTab(ThemeData theme) {
    if (_profile == null) return _profileSetup(theme);
    return _waitlistView(theme);
  }

  Widget _profileSetup(ThemeData theme) {
    return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          const SizedBox(height: 20),
          Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)]),
                  borderRadius: BorderRadius.circular(24)),
              child: const Center(
                  child: Text('\u{1F46A}', style: TextStyle(fontSize: 36)))),
          const SizedBox(height: 20),
          Text('Spielfreunde finden',
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800),
              textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(
              'Erstelle euer Familien-Profil und findet Familien die so ticken wie ihr.',
              style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant, height: 1.4),
              textAlign: TextAlign.center),
          const SizedBox(height: 28),
          _ProfileForm(onSave: (p) async {
            await p.save();
            final uid = AuthService.instance.currentUser?.uid ?? 'guest';
            await _backend.saveProfile(p, uid);
            await _init();
          }),
        ]));
  }

  Widget _waitlistView(ThemeData theme) {
    return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.12))),
              child: Row(children: [
                const Text('\u{1F46A}', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text('Familie ${_profile!.displayName}',
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      Text(
                          _profile!.bio.isNotEmpty
                              ? _profile!.bio
                              : 'Profil aktiv \u{2714}',
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis)
                    ])),
                Row(mainAxisSize: MainAxisSize.min, children: [
                  GestureDetector(
                      onTap: () async {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.remove('spielfreunde.profile');
                        setState(() => _profile = null);
                      },
                      child: Text('Bearbeiten',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.primary))),
                  const SizedBox(width: 12),
                  GestureDetector(
                      onTap: () => _confirmDeleteProfile(theme),
                      child: Text('Loeschen',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.error))),
                ])
              ])),
          const SizedBox(height: 20),
          Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: theme.colorScheme.outlineVariant
                          .withValues(alpha: 0.5))),
              child: Column(children: [
                const Text('\u{1F389}', style: TextStyle(fontSize: 36)),
                const SizedBox(height: 14),
                Text('Dein Profil ist bereit!',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text(
                    'Wir oeffnen die Spielfreunde-Suche sobald genug Familien in deiner Naehe sind.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant, height: 1.4),
                    textAlign: TextAlign.center),
                const SizedBox(height: 16),
                Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.people_rounded,
                          size: 18, color: Color(0xFF8B5CF6)),
                      const SizedBox(width: 8),
                      Text('${_waitlist.total} Familien warten auch',
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF8B5CF6)))
                    ])),
                const SizedBox(height: 12),
                ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                        value: _waitlist.progress,
                        minHeight: 6,
                        backgroundColor: const Color(0xFFE2E8F0),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF8B5CF6)))),
                const SizedBox(height: 6),
                Text('Noch ${_waitlist.remaining} Familien bis Freischaltung',
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: theme.colorScheme.outline)),
              ])),
          const SizedBox(height: 20),
          Text('So wird es aussehen:',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          _familyCard(
              theme,
              'Familie M.',
              'Kreuzberg',
              '\u{1F467} Lina (3) \u{2022} \u{1F466} Ben (5)',
              'Wir suchen Familien fuer Spielplatz-Treffen und gemeinsames Kochen.',
              ['Beduerfnisorientiert', 'Natur'],
              'Nachmittags \u{2022} DE, TR'),
          const SizedBox(height: 10),
          _familyCard(
              theme,
              'Familie S.',
              'Mitte',
              '\u{1F476} Noah (2)',
              'Alleinerziehend, suche Austausch und spontane Treffen.',
              ['Offen', 'Spontan'],
              'Vormittags \u{2022} DE, AR'),
          const SizedBox(height: 20),
          GestureDetector(
              onTap: () => _tabs.animateTo(0),
              child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                      color: const Color(0xFF0EA5A4).withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color:
                              const Color(0xFF0EA5A4).withValues(alpha: 0.12))),
                  child: Row(children: [
                    const Text('\u{1F4A1}', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Text(
                            'Lade Freunde ein — schneller freischalten!',
                            style: theme.textTheme.bodySmall
                                ?.copyWith(fontWeight: FontWeight.w600))),
                    Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                            color: const Color(0xFF0EA5A4),
                            borderRadius: BorderRadius.circular(8)),
                        child: const Text('Einladen',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700)))
                  ]))),
        ]));
  }

  Widget _familyCard(ThemeData theme, String name, String district, String kids,
      String bio, List<String> tags, String meta) {
    return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 3))
            ]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(11)),
                child: const Center(
                    child: Text('\u{1F46A}', style: TextStyle(fontSize: 18)))),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(name,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  Text(district,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant))
                ])),
            Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color:
                        theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(6)),
                child: Text('Bald',
                    style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.outline)))
          ]),
          const SizedBox(height: 10),
          Text(kids,
              style: theme.textTheme.bodySmall
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(bio,
              style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant, height: 1.3)),
          const SizedBox(height: 10),
          Wrap(
              spacing: 6,
              children: tags
                  .map((t) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                          color:
                              const Color(0xFF8B5CF6).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6)),
                      child: Text(t,
                          style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF7C3AED)))))
                  .toList()),
          const SizedBox(height: 8),
          Text(meta,
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: theme.colorScheme.outline)),
        ]));
  }

  Widget _inviteRow(ThemeData theme, IconData icon, Color color, String title,
      String sub, VoidCallback onTap) {
    return GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Container(
            padding: const EdgeInsets.all(14),
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
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, color: color, size: 20)),
              const SizedBox(width: 14),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(title,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    Text(sub,
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant),
                        overflow: TextOverflow.ellipsis)
                  ])),
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 14, color: theme.colorScheme.outline)
            ])));
  }

  Future<void> _confirmDeleteProfile(ThemeData theme) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Profil loeschen?'),
        content:
            const Text('Dein Spielfreunde-Profil wird dauerhaft geloescht. '
                'Du kannst jederzeit ein neues erstellen.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Abbrechen')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.error),
              child: const Text('Loeschen')),
        ],
      ),
    );
    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('spielfreunde.profile');
      // Server-seitig loeschen
      final uid = AuthService.instance.currentUser?.uid ?? 'guest';
      await _backend.deleteProfile(uid);
      if (mounted) setState(() => _profile = null);
    }
  }

  void _showQR(ThemeData theme, ParentCoinService coins) {
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
              const SizedBox(height: 20),
              Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16)),
                  child: QrImageView(
                      data: coins.getInviteLink(),
                      version: QrVersions.auto,
                      size: 200)),
              const SizedBox(height: 14),
              Text(coins.referralCode,
                  style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800, letterSpacing: 2)),
              const SizedBox(height: 20),
              SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Fertig')))
            ])));
  }
}

// ─── Profil-Formular ──────────────────────────────────────────────────────────

class _ProfileForm extends StatefulWidget {
  final Future<void> Function(FamilyMatchProfile) onSave;
  const _ProfileForm({required this.onSave});
  @override
  State<_ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends State<_ProfileForm> {
  final _name = TextEditingController();
  final _district = TextEditingController();
  final _bio = TextEditingController();
  String _form = 'kernfamilie';
  final Set<String> _values = {};
  final Set<String> _looking = {};
  String _avail = 'flexibel';
  final Set<String> _langs = {'de'};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      TextField(
          controller: _name,
          decoration: InputDecoration(
              labelText: 'Vorname',
              hintText: 'z.B. Sarah',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(14)))),
      const SizedBox(height: 12),
      TextField(
          controller: _district,
          decoration: InputDecoration(
              labelText: 'Stadtteil / PLZ',
              hintText: 'z.B. Kreuzberg',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(14)))),
      const SizedBox(height: 16),
      Text('Familienform',
          style: theme.textTheme.labelLarge
              ?.copyWith(fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      Wrap(
          spacing: 8,
          runSpacing: 8,
          children: MatchOptions.familyForms
              .map((f) => ChoiceChip(
                  label: Text(MatchOptions.familyFormLabels[f] ?? f),
                  selected: _form == f,
                  onSelected: (_) => setState(() => _form = f)))
              .toList()),
      const SizedBox(height: 16),
      Text('Unsere Werte',
          style: theme.textTheme.labelLarge
              ?.copyWith(fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      Wrap(
          spacing: 8,
          runSpacing: 8,
          children: MatchOptions.valueOptions
              .map((v) => FilterChip(
                  label: Text(MatchOptions.valueLabels[v] ?? v),
                  selected: _values.contains(v),
                  onSelected: (s) =>
                      setState(() => s ? _values.add(v) : _values.remove(v))))
              .toList()),
      const SizedBox(height: 16),
      Text('Was suchen wir?',
          style: theme.textTheme.labelLarge
              ?.copyWith(fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      Wrap(
          spacing: 8,
          runSpacing: 8,
          children: MatchOptions.lookingForOptions
              .map((l) => FilterChip(
                  label: Text(MatchOptions.lookingForLabels[l] ?? l),
                  selected: _looking.contains(l),
                  onSelected: (s) =>
                      setState(() => s ? _looking.add(l) : _looking.remove(l))))
              .toList()),
      const SizedBox(height: 16),
      Text('Verfuegbarkeit',
          style: theme.textTheme.labelLarge
              ?.copyWith(fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      Wrap(
          spacing: 8,
          runSpacing: 8,
          children: MatchOptions.availOptions
              .map((a) => ChoiceChip(
                  label: Text(MatchOptions.availLabels[a] ?? a),
                  selected: _avail == a,
                  onSelected: (_) => setState(() => _avail = a)))
              .toList()),
      const SizedBox(height: 16),
      Text('Sprachen',
          style: theme.textTheme.labelLarge
              ?.copyWith(fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      Wrap(
          spacing: 8,
          runSpacing: 8,
          children: MatchOptions.languageLabels.entries
              .map((e) => FilterChip(
                  label: Text(e.value),
                  selected: _langs.contains(e.key),
                  onSelected: (s) => setState(
                      () => s ? _langs.add(e.key) : _langs.remove(e.key))))
              .toList()),
      const SizedBox(height: 16),
      TextField(
          controller: _bio,
          maxLength: 140,
          maxLines: 2,
          decoration: InputDecoration(
              labelText: 'Kurze Bio',
              hintText: 'Was sucht ihr?',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(14)))),
      const SizedBox(height: 24),
      SizedBox(
          width: double.infinity,
          child: FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14))),
              child: const Text('Profil erstellen'))),
    ]);
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty || _district.text.trim().isEmpty) return;
    final p = FamilyMatchProfile(
        displayName: _name.text.trim(),
        district: _district.text.trim(),
        children: const [],
        languages: _langs.toList(),
        familyForm: _form,
        values: _values.toList(),
        lookingFor: _looking.toList(),
        availability: _avail,
        bio: _bio.text.trim(),
        createdAt: DateTime.now());
    await widget.onSave(p);
  }
}
