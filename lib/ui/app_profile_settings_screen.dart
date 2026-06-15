import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trusted_circle_demo/logic/auth_service.dart';
import 'package:trusted_circle_demo/main.dart';
import 'package:trusted_circle_demo/models/trusted_device.dart';
import 'package:trusted_circle_demo/ui/contacts_screen.dart';
import 'package:trusted_circle_demo/ui/device_management_screen.dart';
import 'package:trusted_circle_demo/ui/family_profile_screen.dart';
import 'package:trusted_circle_demo/ui/safety_guide_screen.dart';
import 'package:trusted_circle_demo/widgets/ala_rengin_flag_painter.dart';

class AppProfileSettingsScreen extends StatefulWidget {
  const AppProfileSettingsScreen({
    super.key,
    required this.devices,
    required this.onRevoke,
  });

  final List<TrustedDevice> devices;
  final Future<bool> Function(String deviceUuid, String deviceName) onRevoke;

  @override
  State<AppProfileSettingsScreen> createState() => _AppProfileSettingsScreenState();
}

class _AppProfileSettingsScreenState extends State<AppProfileSettingsScreen> {
  static const String _kRemindersEnabled = 'pp_pref_reminders_enabled';
  static const String _kFamilyDigestEnabled = 'pp_pref_family_digest_enabled';

  bool _isDarkMode = false;
  bool _remindersEnabled = true;
  bool _familyDigestEnabled = true;
  String _currentLanguage = 'de';
  bool _loadingPrefs = true;

  final List<Map<String, String>> _languages = const [
    {'code': 'de', 'name': 'Deutsch', 'flag': '🇩🇪', 'nativeName': 'Deutsch'},
    {'code': 'en', 'name': 'English', 'flag': '🇬🇧', 'nativeName': 'English'},
    {'code': 'fr', 'name': 'Français', 'flag': '🇫🇷', 'nativeName': 'Français'},
    {'code': 'es', 'name': 'Español', 'flag': '🇪🇸', 'nativeName': 'Español'},
    {'code': 'it', 'name': 'Italiano', 'flag': '🇮🇹', 'nativeName': 'Italiano'},
    {'code': 'nl', 'name': 'Nederlands', 'flag': '🇳🇱', 'nativeName': 'Nederlands'},
    {'code': 'pt', 'name': 'Português', 'flag': '🇵🇹', 'nativeName': 'Português'},
    {'code': 'ar', 'name': 'العربية', 'flag': '🇸🇦', 'nativeName': 'العربية'},
    {'code': 'fa', 'name': 'فارسی', 'flag': '🇮🇷', 'nativeName': 'فارسی'},
    {'code': 'ku', 'name': 'Kurdî', 'flag': '🔶', 'nativeName': 'Kurdî'},
    {'code': 'ckb', 'name': 'کوردی', 'flag': '🔶', 'nativeName': 'کوردی'},
    {'code': 'zh', 'name': '中文', 'flag': '🇨🇳', 'nativeName': '中文'},
    {'code': 'ja', 'name': '日本語', 'flag': '🇯🇵', 'nativeName': '日本語'},
    {'code': 'ko', 'name': '한국어', 'flag': '🇰🇷', 'nativeName': '한국어'},
    {'code': 'tr', 'name': 'Türkçe', 'flag': '🇹🇷', 'nativeName': 'Türkçe'},
    {'code': 'ru', 'name': 'Русский', 'flag': '🇷🇺', 'nativeName': 'Русский'},
  ];

  @override
  void initState() {
    super.initState();
    _isDarkMode = themeService.isDarkMode;
    _currentLanguage = languageService.currentLanguage;
    themeService.addListener(_onThemeChanged);
    languageService.addListener(_onLanguageChanged);
    _loadPreferences();
  }

  @override
  void dispose() {
    themeService.removeListener(_onThemeChanged);
    languageService.removeListener(_onLanguageChanged);
    super.dispose();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _remindersEnabled = prefs.getBool(_kRemindersEnabled) ?? true;
      _familyDigestEnabled = prefs.getBool(_kFamilyDigestEnabled) ?? true;
      _loadingPrefs = false;
    });
  }

  void _onThemeChanged() {
    if (!mounted) return;
    setState(() => _isDarkMode = themeService.isDarkMode);
  }

  void _onLanguageChanged() {
    if (!mounted) return;
    setState(() => _currentLanguage = languageService.currentLanguage);
  }

  Future<void> _setReminderEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kRemindersEnabled, value);
    if (!mounted) return;
    setState(() => _remindersEnabled = value);
  }

  Future<void> _setFamilyDigestEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kFamilyDigestEnabled, value);
    if (!mounted) return;
    setState(() => _familyDigestEnabled = value);
  }

  Future<void> _setDarkMode(bool value) async {
    await themeService.setDarkMode(value);
    DemoApp.setThemeMode(value ? ThemeMode.dark : ThemeMode.light);
  }

  Future<void> _selectLanguage(String code) async {
    await languageService.setLanguage(code);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _logout() async {
    await AuthService.instance.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => AuthGate(
          devices: widget.devices,
          onRevoke: widget.onRevoke,
        ),
      ),
      (route) => false,
    );
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Abmelden?'),
        content: const Text('Du wirst aus deinem Konto ausgeloggt.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Abmelden'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await _logout();
    }
  }

  void _showLanguageSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.7,
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Sprache waehlen',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    itemCount: _languages.length,
                    itemBuilder: (context, index) {
                      final language = _languages[index];
                      final code = language['code']!;
                      final selected = code == _currentLanguage;

                      Widget leading;
                      if (code == 'ku' || code == 'ckb') {
                        leading = const AlaRenginFlag(width: 24, height: 15);
                      } else {
                        leading = Text(
                          language['flag'] ?? '🌐',
                          style: const TextStyle(fontSize: 22),
                        );
                      }

                      return ListTile(
                        leading: leading,
                        title: Text(language['nativeName'] ?? ''),
                        subtitle: Text(language['name'] ?? ''),
                        trailing: selected
                            ? Icon(
                                Icons.check_circle_rounded,
                                color: Theme.of(context).colorScheme.primary,
                              )
                            : null,
                        selected: selected,
                        onTap: () => _selectLanguage(code),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = AuthService.instance.currentUser;
    final displayName = user?.displayName.trim().isNotEmpty == true
        ? user!.displayName.trim()
        : 'Parent';
    final email = user?.email ?? 'Kein Konto verbunden';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil & Einstellungen'),
      ),
      body: _loadingPrefs
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                _buildProfileHero(theme, displayName, email),
                const SizedBox(height: 14),
                _sectionTitle('App Steuerung'),
                const SizedBox(height: 8),
                _settingsCard(
                  children: [
                    SwitchListTile(
                      secondary: const Icon(Icons.dark_mode_rounded),
                      title: const Text('Dark Mode'),
                      subtitle: const Text('Sofort fuer die ganze App uebernehmen'),
                      value: _isDarkMode,
                      onChanged: _setDarkMode,
                    ),
                    _divider(theme),
                    ListTile(
                      leading: const Icon(Icons.language_rounded),
                      title: const Text('Sprache'),
                      subtitle: Text(
                        _languages.firstWhere(
                          (l) => l['code'] == _currentLanguage,
                          orElse: () => _languages.first,
                        )['nativeName'] ??
                            _currentLanguage,
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: _showLanguageSheet,
                    ),
                    _divider(theme),
                    SwitchListTile(
                      secondary: const Icon(Icons.notifications_active_rounded),
                      title: const Text('Erinnerungen'),
                      subtitle: const Text('Kalender- und Termin-Reminder aktiv'),
                      value: _remindersEnabled,
                      onChanged: _setReminderEnabled,
                    ),
                    _divider(theme),
                    SwitchListTile(
                      secondary: const Icon(Icons.summarize_rounded),
                      title: const Text('Familien Tagesuebersicht'),
                      subtitle: const Text('Taegliche Zusammenfassung aktivieren'),
                      value: _familyDigestEnabled,
                      onChanged: _setFamilyDigestEnabled,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _sectionTitle('Familie & Sicherheit'),
                const SizedBox(height: 8),
                _settingsCard(
                  children: [
                    _navTile(
                      icon: Icons.family_restroom_rounded,
                      title: 'Familienprofil',
                      subtitle: 'Mitglieder, Interessen und Account-Infos',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => FamilyProfileScreen(
                              devices: widget.devices,
                              onRevoke: widget.onRevoke,
                            ),
                          ),
                        );
                      },
                    ),
                    _divider(theme),
                    _navTile(
                      icon: Icons.shield_rounded,
                      title: 'Sicherheitsleitfaden',
                      subtitle: 'Praevention, Notfalltipps und Schutz',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const SafetyGuideScreen(),
                          ),
                        );
                      },
                    ),
                    _divider(theme),
                    _navTile(
                      icon: Icons.contact_phone_rounded,
                      title: 'Notfallkontakte',
                      subtitle: 'Wichtige Kontakte schnell erreichen',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ContactsScreen(),
                          ),
                        );
                      },
                    ),
                    _divider(theme),
                    _navTile(
                      icon: Icons.phonelink_setup_rounded,
                      title: 'Vertrauensgeraete',
                      subtitle: 'Geraete verwalten und Zugriff kontrollieren',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => DeviceManagementScreen(
                              devices: widget.devices,
                              onRevoke: widget.onRevoke,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _sectionTitle('Konto'),
                const SizedBox(height: 8),
                _settingsCard(
                  children: [
                    _navTile(
                      icon: Icons.feedback_rounded,
                      title: 'Bewertung & Feedback',
                      subtitle: 'Hilf uns die App weiter zu verbessern',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Danke! Feedback-Bereich folgt als naechstes.'),
                          ),
                        );
                      },
                    ),
                    _divider(theme),
                    _navTile(
                      icon: Icons.gavel_rounded,
                      title: 'Rechtliches',
                      subtitle: 'Datenschutz, Nutzungsbedingungen und Hinweise',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Rechtliche Dokumente werden hier gebuendelt.'),
                          ),
                        );
                      },
                    ),
                    _divider(theme),
                    ListTile(
                      leading: const Icon(Icons.logout_rounded, color: Color(0xFFB45309)),
                      title: const Text(
                        'Abmelden',
                        style: TextStyle(color: Color(0xFFB45309), fontWeight: FontWeight.w700),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: _confirmLogout,
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildProfileHero(ThemeData theme, String displayName, String email) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF0F766E), Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1D4ED8).withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            child: Text(
              displayName.characters.first.toUpperCase(),
              style: theme.textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.88),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    userStatusLabel(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String userStatusLabel() {
    final user = AuthService.instance.currentUser;
    if (user == null) return 'Offline Profil';
    if (user.isPremium) return 'Premium Familie';
    if (user.isTrialActive) return 'Testphase: ${user.trialDaysRemaining} Tage';
    return 'Basis Konto';
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: Color(0xFF0F172A),
      ),
    );
  }

  Widget _settingsCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _divider(ThemeData theme) {
    return Divider(height: 1, color: theme.colorScheme.outlineVariant.withValues(alpha: 0.55));
  }

  Widget _navTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}
