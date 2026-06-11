import 'package:flutter/material.dart';
import 'package:trusted_circle_demo/main.dart';
import 'package:trusted_circle_demo/l10n/app_localizations_all.dart';
import 'package:trusted_circle_demo/models/trusted_device.dart';
import 'package:trusted_circle_demo/ui/device_management_screen.dart';
import 'package:trusted_circle_demo/widgets/ala_rengin_flag_painter.dart';

class FamilyProfileScreen extends StatefulWidget {
  final List<TrustedDevice> devices;
  final Future<bool> Function(String deviceUuid, String deviceName) onRevoke;

  const FamilyProfileScreen(
      {super.key, required this.devices, required this.onRevoke});

  @override
  State<FamilyProfileScreen> createState() => _FamilyProfileScreenState();
}

class _FamilyProfileScreenState extends State<FamilyProfileScreen> {
  late bool _isDarkMode;
  String _currentLanguage = 'de';
  final List<String> _familyMembers = ['Mom', 'Dad', 'Emma', 'Liam'];
  final List<String> _interests = [
    '#Family',
    '#Sport',
    '#Education',
    '#Leisure',
    '#Health'
  ];
  late final List<Map<String, String>> _languages;

  @override
  void initState() {
    super.initState();
    _isDarkMode = themeService.isDarkMode;
    // Nutze den globalen languageService
    _currentLanguage = languageService.currentLanguage;
    languageService.addListener(_onLanguageChanged);
    themeService.addListener(_onThemeChanged);

    _languages = [
      {
        'code': 'de',
        'name': 'Deutsch',
        'flag': '🇩🇪',
        'nativeName': 'Deutsch'
      },
      {
        'code': 'en',
        'name': 'English',
        'flag': '🇬🇧',
        'nativeName': 'English'
      },
      {
        'code': 'fr',
        'name': 'Français',
        'flag': '🇫🇷',
        'nativeName': 'Français'
      },
      {
        'code': 'es',
        'name': 'Español',
        'flag': '🇪🇸',
        'nativeName': 'Español'
      },
      {
        'code': 'it',
        'name': 'Italiano',
        'flag': '🇮🇹',
        'nativeName': 'Italiano'
      },
      {
        'code': 'nl',
        'name': 'Nederlands',
        'flag': '🇳🇱',
        'nativeName': 'Nederlands'
      },
      {
        'code': 'pt',
        'name': 'Português',
        'flag': '🇵🇹',
        'nativeName': 'Português'
      },
      {
        'code': 'ar',
        'name': 'العربية',
        'flag': '🇸🇦',
        'nativeName': 'العربية'
      },
      {'code': 'fa', 'name': 'فارسی', 'flag': '🇮🇷', 'nativeName': 'فارسی'},
      {'code': 'ku', 'name': 'Kurdî', 'flag': '🔶', 'nativeName': 'Kurdî'},
      {'code': 'ckb', 'name': 'کوردی', 'flag': '🔶', 'nativeName': 'کوردی'},
      {'code': 'zh', 'name': '中文', 'flag': '🇨🇳', 'nativeName': '中文'},
      {'code': 'ja', 'name': '日本語', 'flag': '🇯🇵', 'nativeName': '日本語'},
      {'code': 'ko', 'name': '한국어', 'flag': '🇰🇷', 'nativeName': '한국어'},
      {'code': 'tr', 'name': 'Türkçe', 'flag': '🇹🇷', 'nativeName': 'Türkçe'},
      {
        'code': 'ru',
        'name': 'Русский',
        'flag': '🇷🇺',
        'nativeName': 'Русский'
      },
    ];
  }

  @override
  void dispose() {
    themeService.removeListener(_onThemeChanged);
    languageService.removeListener(_onLanguageChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    if (mounted) {
      setState(() {
        _isDarkMode = themeService.isDarkMode;
      });
    }
  }

  void _onLanguageChanged() {
    if (mounted) {
      setState(() {
        _currentLanguage = languageService.currentLanguage;
      });
    }
  }

  String _t(String key) => AppStringsManager.getString(_currentLanguage, key);

  void _showLanguageSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => Material(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                _t('language'),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            Divider(height: 1, color: Colors.grey[300]),
            Expanded(
              child: ListView.builder(
                itemCount: _languages.length,
                itemBuilder: (context, index) {
                  final lang = _languages[index];
                  final code = lang['code']!;
                  final isSelected = code == _currentLanguage;

                  // Special handling for Kurdish languages to show Ala rengin flag
                  Widget flagWidget;
                  if (code == 'ku' || code == 'ckb') {
                    flagWidget = AlaRenginFlag(width: 32, height: 20);
                  } else {
                    flagWidget = Text(lang['flag'] ?? '🌐',
                        style: const TextStyle(fontSize: 28));
                  }

                  return ListTile(
                    leading: flagWidget,
                    title: Text(
                      lang['nativeName'] ?? '',
                      style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text(lang['name'] ?? ''),
                    trailing: isSelected
                        ? Icon(Icons.check_circle,
                            color: Theme.of(context).colorScheme.primary)
                        : null,
                    selected: isSelected,
                    selectedTileColor:
                        Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    onTap: () async {
                      // Nutze den globalen languageService und warte auf das Ergebnis
                      await languageService.setLanguage(code);
                      if (mounted) {
                        Navigator.pop(context);
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteAccountConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: const Text(
          'Konto löschen?',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
        ),
        content: const Text(
          'Dies kann nicht rückgängig gemacht werden. Alle Ihre Daten werden gelöscht.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_t('cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Konto gelöscht'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Löschen', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const primaryColor = Color(0xFFBDB2FF);
    const accentColor = Color(0xFFFFC6FF);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(primaryColor, accentColor),
            const SizedBox(height: 24),
            _buildFamilyAvatars(primaryColor),
            const SizedBox(height: 24),
            _buildSubscriptionCard(primaryColor, accentColor),
            const SizedBox(height: 24),
            _buildInterests(theme),
            const SizedBox(height: 24),
            _buildSettings(primaryColor, theme),
            const SizedBox(height: 24),
            _buildAccountSection(theme),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Color primary, Color accent) {
    return Stack(
      children: [
        Container(
          height: 200,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primary.withOpacity(0.8), accent.withOpacity(0.6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(25),
              bottomRight: Radius.circular(25),
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.family_restroom,
                    size: 64, color: Colors.white),
                const SizedBox(height: 12),
                Text(
                  _t('family_profile_title'),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFamilyAvatars(Color primary) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _t('family_members'),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 92,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _familyMembers.length + 1,
              itemBuilder: (context, index) {
                if (index == _familyMembers.length) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(_t('add_member'))),
                        );
                      },
                      child: Container(
                        width: 80,
                        decoration: BoxDecoration(
                          color: primary.withOpacity(0.2),
                          border: Border.all(color: primary, width: 2),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Icon(Icons.add_circle, color: primary, size: 40),
                      ),
                    ),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: primary.withOpacity(0.3),
                        child: Text(
                          _familyMembers[index][0],
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _familyMembers[index],
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionCard(Color primary, Color accent) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
          side: BorderSide(color: primary.withOpacity(0.2), width: 1),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            gradient: LinearGradient(
              colors: [primary.withOpacity(0.1), accent.withOpacity(0.1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(20),
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child:
                  const Icon(Icons.card_membership, color: Color(0xFFBDB2FF)),
            ),
            title: Text(
              _t('premium_subscription'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            subtitle: Text(_t('subscription_active')),
            trailing: TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(_t('subscription_manage'))),
                );
              },
              child: Text(_t('subscription_manage')),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInterests(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _t('interests'),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _interests.map((interest) {
              return FilterChip(
                label: Text(interest),
                onSelected: (selected) {},
                backgroundColor: const Color(0xFFBDB2FF).withOpacity(0.2),
                labelStyle: const TextStyle(
                  color: Color(0xFFBDB2FF),
                  fontWeight: FontWeight.w600,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSettings(Color primary, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _t('settings'),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
              side: BorderSide(color: primary.withOpacity(0.1), width: 1),
            ),
            child: Column(
              children: [
                ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  leading: Builder(
                    builder: (context) {
                      final currentLang = _languages
                          .firstWhere((l) => l['code'] == _currentLanguage);
                      final code = currentLang['code']!;

                      // Special handling for Kurdish languages to show Ala rengin flag
                      if (code == 'ku' || code == 'ckb') {
                        return AlaRenginFlag(width: 24, height: 15);
                      } else {
                        final flagValue = currentLang['flag']!;
                        return Text(flagValue,
                            style: const TextStyle(fontSize: 20));
                      }
                    },
                  ),
                  title: Text(_t('language')),
                  subtitle: Text(_languages.firstWhere(
                          (l) => l['code'] == _currentLanguage)['nativeName'] ??
                      ''),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                  onTap: _showLanguageSelector,
                ),
                Divider(height: 1, color: primary.withOpacity(0.1)),
                SwitchListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  secondary:
                      const Icon(Icons.dark_mode, color: Color(0xFFBDB2FF)),
                  title: Text(_t('dark_mode')),
                  value: _isDarkMode,
                  onChanged: (value) async {
                    setState(() => _isDarkMode = value);
                    await themeService.setDarkMode(value);
                    DemoApp.setThemeMode(
                        value ? ThemeMode.dark : ThemeMode.light);
                  },
                ),
                Divider(height: 1, color: primary.withOpacity(0.1)),
                SwitchListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  secondary:
                      const Icon(Icons.notifications, color: Color(0xFFBDB2FF)),
                  title: Text(_t('notifications')),
                  value: true,
                  onChanged: (value) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(_t('notifications'))),
                    );
                  },
                ),
                Divider(height: 1, color: primary.withOpacity(0.1)),
                ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  leading:
                      const Icon(Icons.privacy_tip, color: Color(0xFFBDB2FF)),
                  title: Text(_t('privacy')),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(_t('privacy'))),
                    );
                  },
                ),
                Divider(height: 1, color: primary.withOpacity(0.1)),
                ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  leading: const Icon(Icons.phonelink_setup,
                      color: Color(0xFFBDB2FF)),
                  title: const Text('Vertrauensgeraete'),
                  subtitle: const Text('Aktive Geraete anzeigen und verwalten'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                  onTap: () {
                    Navigator.push(
                      context,
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
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSection(ThemeData theme) {
    const primaryColor = Color(0xFFBDB2FF);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _t('account'),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
              side: BorderSide(color: primaryColor.withOpacity(0.1), width: 1),
            ),
            child: Column(
              children: [
                ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  leading: const Icon(Icons.star, color: Color(0xFFBDB2FF)),
                  title: Text(_t('engagement')),
                  subtitle: Text(_t('engagement_subtitle')),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(_t('engagement'))),
                    );
                  },
                ),
                Divider(height: 1, color: primaryColor.withOpacity(0.1)),
                ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  leading:
                      const Icon(Icons.description, color: Color(0xFFBDB2FF)),
                  title: Text(_t('legal')),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(_t('legal'))),
                    );
                  },
                ),
                Divider(height: 1, color: primaryColor.withOpacity(0.1)),
                ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  leading: const Icon(Icons.logout, color: Colors.orange),
                  title: Text(_t('logout'),
                      style: const TextStyle(color: Colors.orange)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(_t('logged_out'))),
                    );
                  },
                ),
                Divider(height: 1, color: primaryColor.withOpacity(0.1)),
                ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  leading: const Icon(Icons.delete_forever, color: Colors.red),
                  title: Text(_t('delete_account'),
                      style: const TextStyle(
                          color: Colors.red, fontWeight: FontWeight.bold)),
                  trailing: const Icon(Icons.arrow_forward_ios,
                      size: 18, color: Colors.red),
                  onTap: _showDeleteAccountConfirmation,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
