import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:parentpeak/logic/auth_service.dart';
import 'package:parentpeak/logic/theme_service.dart';
import 'package:parentpeak/logic/language_service.dart';
import 'package:parentpeak/main.dart';
import 'package:parentpeak/models/trusted_device.dart';
import 'package:parentpeak/ui/auth/paywall_screen.dart';
import 'package:parentpeak/config/api_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Profil-Screen — warm, simpel, elternfreundlich.
///
/// Zeigt: Profilkarte, Abo-Status, Kinder, Einstellungen, Rechtliches.
/// Kein Admin-Panel, kein Geräte-Management, kein Rollen-System.
class ProfileSafetyScreen extends StatefulWidget {
  const ProfileSafetyScreen({
    super.key,
    required this.devices,
    required this.onRevoke,
    this.onBack,
  });

  final List<TrustedDevice> devices;
  final Future<bool> Function(String deviceUuid, String deviceName) onRevoke;
  final VoidCallback? onBack;

  @override
  State<ProfileSafetyScreen> createState() => _ProfileSafetyScreenState();
}

class _ProfileSafetyScreenState extends State<ProfileSafetyScreen> {
  List<_ChildInfo> _children = [];

  @override
  void initState() {
    super.initState();
    _loadChildren();
  }

  Future<void> _loadChildren() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('onboarding.parent_role') ?? '';
    // Lade gespeicherte Kinder oder zeige Placeholder basierend auf Onboarding
    final children = <_ChildInfo>[];
    final savedChildren = prefs.getStringList('profile.children') ?? [];
    for (final raw in savedChildren) {
      final parts = raw.split('|');
      if (parts.length >= 2) {
        children.add(_ChildInfo(name: parts[0], age: parts[1]));
      }
    }
    if (mounted) setState(() => _children = children);
  }

  Future<void> _addChild() async {
    final result = await _showAddChildDialog();
    if (result == null) return;
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('profile.children') ?? [];
    saved.add('${result.name}|${result.age}');
    await prefs.setStringList('profile.children', saved);
    await _loadChildren();
  }

  Future<_ChildInfo?> _showAddChildDialog() async {
    final nameCtrl = TextEditingController();
    final ageCtrl = TextEditingController();

    return showModalBottomSheet<_ChildInfo>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final viewInsets = MediaQuery.of(ctx).viewInsets;
        return Container(
          padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + viewInsets.bottom),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Kind hinzufügen',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Damit die Tipps zum Alter passen.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'z.B. Emma',
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ageCtrl,
                decoration: const InputDecoration(
                  labelText: 'Alter',
                  hintText: 'z.B. 4 Jahre',
                ),
                keyboardType: TextInputType.text,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    final name = nameCtrl.text.trim();
                    final age = ageCtrl.text.trim();
                    if (name.isEmpty) return;
                    Navigator.pop(ctx,
                        _ChildInfo(name: name, age: age.isEmpty ? '?' : age));
                  },
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Hinzufügen'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = AuthService.instance.currentUser;
    final displayName = (user?.displayName.trim().isNotEmpty ?? false)
        ? user!.displayName.trim()
        : 'Elternteil';
    final email = user?.email ?? '';
    final isPremium = user?.isPremium ?? false;
    final trialDays = user?.trialDaysRemaining ?? 0;
    final hasAccess = user?.hasFullAccess ?? false;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Kompakter Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    Text(
                      'Profil',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: _logout,
                      icon: Icon(Icons.logout_rounded,
                          color: theme.colorScheme.onSurfaceVariant),
                      tooltip: 'Abmelden',
                    ),
                  ],
                ),
              ),
            ),

            // Profilkarte
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: _buildProfileCard(theme, displayName, email),
              ),
            ),

            // Abo-Status
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: _buildSubscriptionCard(
                    theme, isPremium, trialDays, hasAccess),
              ),
            ),

            // Kinder
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: _buildChildrenSection(theme),
              ),
            ),

            // Einstellungen
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: _buildSettingsSection(theme),
              ),
            ),

            // Rechtliches & Account
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                child: _buildLegalSection(theme),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Profilkarte ────────────────────────────────────────────────────────────

  Widget _buildProfileCard(ThemeData theme, String name, String email) {
    final initials = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                initials,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (email.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Abo-Status ─────────────────────────────────────────────────────────────

  Widget _buildSubscriptionCard(
      ThemeData theme, bool isPremium, int trialDays, bool hasAccess) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isPremium
            ? const Color(0xFFF0FDF4)
            : hasAccess
                ? const Color(0xFFFEFCE8)
                : theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPremium
              ? const Color(0xFF86EFAC)
              : hasAccess
                  ? const Color(0xFFFDE047)
                  : theme.colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isPremium
                  ? const Color(0xFF16A34A).withValues(alpha: 0.12)
                  : const Color(0xFFF59E0B).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isPremium
                  ? Icons.workspace_premium_rounded
                  : Icons.card_giftcard_rounded,
              color:
                  isPremium ? const Color(0xFF16A34A) : const Color(0xFFF59E0B),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPremium ? 'Premium aktiv' : 'Free-Version',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: isPremium
                        ? const Color(0xFF16A34A)
                        : theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  isPremium
                      ? 'Alle Features freigeschaltet'
                      : hasAccess
                          ? 'Noch $trialDays Tage Trial'
                          : 'Eingeschränkter Zugang',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (!isPremium)
            FilledButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PaywallScreen(
                      onSubscribed: () {
                        Navigator.pop(context);
                        setState(() {});
                      },
                    ),
                  ),
                );
              },
              style: FilledButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Upgrade'),
            ),
        ],
      ),
    );
  }

  // ─── Kinder ─────────────────────────────────────────────────────────────────

  Widget _buildChildrenSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('\u{1F9D2}', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Eure Kinder',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              GestureDetector(
                onTap: _addChild,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded,
                          size: 16, color: theme.colorScheme.primary),
                      const SizedBox(width: 4),
                      Text(
                        'Kind',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_children.isEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Füge eure Kinder hinzu, damit Tipps und Impulse zum Alter passen.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          if (_children.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _children.map((child) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('\u{1F476}', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Text(
                        child.name,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (child.age.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Text(
                          child.age,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Einstellungen ──────────────────────────────────────────────────────────

  Widget _buildSettingsSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            'Einstellungen',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        _buildSettingsTile(
          theme,
          icon: Icons.dark_mode_rounded,
          title: 'Dark Mode',
          trailing: Switch.adaptive(
            value: themeService.isDarkMode,
            onChanged: (value) {
              themeService.setDarkMode(value);
              DemoApp.setThemeMode(value ? ThemeMode.dark : ThemeMode.light);
              setState(() {});
            },
          ),
        ),
        _buildSettingsTile(
          theme,
          icon: Icons.language_rounded,
          title: 'Sprache',
          subtitle:
              languageService.currentLanguage == 'de' ? 'Deutsch' : 'English',
          onTap: () async {
            final newLang =
                languageService.currentLanguage == 'de' ? 'en' : 'de';
            await languageService.setLanguage(newLang);
            if (mounted) setState(() {});
          },
        ),
        _buildSettingsTile(
          theme,
          icon: Icons.notifications_rounded,
          title: 'Benachrichtigungen',
          subtitle: 'Aktiviert',
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildSettingsTile(
    ThemeData theme, {
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(icon, size: 22, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                if (trailing != null) trailing,
                if (trailing == null && onTap != null)
                  Icon(Icons.chevron_right_rounded,
                      color: theme.colorScheme.outline),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Rechtliches ────────────────────────────────────────────────────────────

  Widget _buildLegalSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            'Rechtliches',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        _buildSettingsTile(
          theme,
          icon: Icons.description_rounded,
          title: 'Datenschutz',
          onTap: () => _openUrl(APIConfig.getPrivacyPolicyUrl()),
        ),
        _buildSettingsTile(
          theme,
          icon: Icons.gavel_rounded,
          title: 'Nutzungsbedingungen',
          onTap: () => _openUrl(APIConfig.getTermsOfServiceUrl()),
        ),
        _buildSettingsTile(
          theme,
          icon: Icons.mail_rounded,
          title: 'Kontakt & Support',
          subtitle: APIConfig.getContactEmail() ?? '',
          onTap: () => _openUrl(APIConfig.getContactSupportUrl()),
        ),
        const SizedBox(height: 12),
        // Account löschen
        Center(
          child: TextButton(
            onPressed: _showDeleteAccountDialog,
            child: Text(
              'Account löschen',
              style: TextStyle(
                color: theme.colorScheme.error,
                fontSize: 13,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'Parentpeak v1.0.0',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ),
      ],
    );
  }

  // ─── Aktionen ───────────────────────────────────────────────────────────────

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Abmelden?'),
        content: const Text('Du wirst ausgeloggt.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Abmelden'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await AuthService.instance.logout();
    if (mounted) setState(() {});
  }

  void _showDeleteAccountDialog() {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning_rounded,
                size: 40, color: theme.colorScheme.error),
            const SizedBox(height: 14),
            Text(
              'Account wirklich löschen?',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Alle deine Daten werden unwiderruflich gelöscht. Das kann nicht rückgängig gemacht werden.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  // Account-Löschung wird hier implementiert
                },
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.error,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Ja, Account löschen'),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Abbrechen'),
            ),
          ],
        ),
      ),
    );
  }

  void _openUrl(String? url) {
    if (url == null || url.isEmpty) return;
    // url_launcher wird hier verwendet
  }
}

class _ChildInfo {
  final String name;
  final String age;
  const _ChildInfo({required this.name, required this.age});
}
