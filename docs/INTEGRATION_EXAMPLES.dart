// ============================================================
// INTEGRATIONS-BEISPIEL FÜR FAMILY PROFILE SCREEN
// ============================================================
// Diese Datei zeigt wie der Family Profile Screen in der App integriert wird

import 'package:flutter/material.dart';
import 'package:trusted_circle_demo/ui/family_profile_screen.dart';
import 'package:trusted_circle_demo/l10n/app_localizations_all.dart';

// ============================================================
// 1. IMPORT IN MAIN.DART
// ============================================================
// import 'package:trusted_circle_demo/ui/family_profile_screen.dart';
// import 'package:trusted_circle_demo/l10n/app_localizations_all.dart';

// ============================================================
// 2. NAVIGATION ZUM FAMILY PROFILE SCREEN
// ============================================================
void navigateToFamilyProfile(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => const FamilyProfileScreen(),
    ),
  );
}

// ============================================================
// 3. BEISPIEL: BOTTOM TAB NAVIGATION
// ============================================================
class ExampleAppShellWithFamilyProfile extends StatefulWidget {
  const ExampleAppShellWithFamilyProfile({super.key});

  @override
  State<ExampleAppShellWithFamilyProfile> createState() =>
      _ExampleAppShellWithFamilyProfileState();
}

class _ExampleAppShellWithFamilyProfileState
    extends State<ExampleAppShellWithFamilyProfile> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildPage(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildPage(int index) {
    switch (index) {
      case 0:
        return const Center(child: Text('Home Screen'));
      case 1:
        return const Center(child: Text('Chat Screen'));
      case 2:
        return const FamilyProfileScreen(); // ✅ Hier wird der Screen verwendet
      default:
        return const SizedBox();
    }
  }
}

// ============================================================
// 4. BEISPIEL: FLOATING ACTION BUTTON ZUM ÖFFNEN
// ============================================================
class HomeScreenWithProfileButton extends StatelessWidget {
  const HomeScreenWithProfileButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: const Center(child: Text('Home Content')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => navigateToFamilyProfile(context),
        tooltip: 'Family Profile',
        child: const Icon(Icons.person),
      ),
    );
  }
}

// ============================================================
// 5. SPRACH-WECHSEL PROGRAMMATISCH (OHNE UI)
// ============================================================
class LanguageSwitchExample extends StatefulWidget {
  const LanguageSwitchExample({super.key});

  @override
  State<LanguageSwitchExample> createState() => _LanguageSwitchExampleState();
}

class _LanguageSwitchExampleState extends State<LanguageSwitchExample> {
  String _currentLang = 'de';

  void _switchLanguage(String langCode) {
    setState(() => _currentLang = langCode);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Sprache geändert zu: ${AppStringsManager.languages[langCode]?['nativeName']}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Language Selector')),
      body: GridView.count(
        crossAxisCount: 3,
        children: AppStringsManager.languages.entries.map((entry) {
          final code = entry.key;
          final lang = entry.value;
          final isSelected = code == _currentLang;

          return InkWell(
            onTap: () => _switchLanguage(code),
            child: Container(
              decoration: BoxDecoration(
                border: isSelected
                    ? Border.all(color: Colors.blue, width: 3)
                    : null,
                color: isSelected ? Colors.blue.withOpacity(0.2) : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(lang['flag'] ?? '🌐', style: const TextStyle(fontSize: 40)),
                  const SizedBox(height: 8),
                  Text(lang['nativeName'] ?? '', textAlign: TextAlign.center),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ============================================================
// 6. BEISPIEL: STRINGS ABRUFEN PROGRAMMATISCH
// ============================================================
class LocalizationExampleWidget extends StatelessWidget {
  const LocalizationExampleWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // RTL-Sprache
    final isArabic = true;
    final langCode = isArabic ? 'ar' : 'de';

    return Scaffold(
      appBar: AppBar(title: const Text('Localization Example')),
      body: ListView(
        children: [
          ListTile(
            title: Text(
              AppStringsManager.getString(langCode, 'family_profile_title'),
            ),
          ),
          ListTile(
            title: Text(
              AppStringsManager.getString(langCode, 'family_members'),
            ),
          ),
          ListTile(
            title: Text(
              AppStringsManager.getString(langCode, 'dark_mode'),
            ),
          ),
          ListTile(
            title: Text(
              AppStringsManager.getString(langCode, 'delete_account'),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// 7. BEISPIEL: RTL-AWARE LAYOUT BUILDER
// ============================================================
class RtlAwareLayout extends StatefulWidget {
  const RtlAwareLayout({super.key});

  @override
  State<RtlAwareLayout> createState() => _RtlAwareLayoutState();
}

class _RtlAwareLayoutState extends State<RtlAwareLayout> {
  String _language = 'de';

  @override
  Widget build(BuildContext context) {
    final isRtl = AppStringsManager.isRtl(_language);

    return Scaffold(
      appBar: AppBar(title: const Text('RTL Demo')),
      body: Column(
        children: [
          Wrap(
            children: AppStringsManager.languages.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton(
                  onPressed: () => setState(() => _language = entry.key),
                  child: Text(entry.value['flag'] ?? ''),
                ),
              );
            }).toList(),
          ),
          const Divider(),
          Expanded(
            child: Container(
              color: Colors.blue.withOpacity(0.2),
              child: Column(
                crossAxisAlignment:
                    isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  PaddingDirectional(
                    start: 20,
                    end: 20,
                    child: Column(
                      crossAxisAlignment: isRtl
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${AppStringsManager.languages[_language]?['nativeName']} (${isRtl ? 'RTL' : 'LTR'})',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          textDirection:
                              isRtl ? TextDirection.rtl : TextDirection.ltr,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          AppStringsManager.getString(
                              _language, 'family_profile_title'),
                          style: const TextStyle(fontSize: 18),
                          textDirection:
                              isRtl ? TextDirection.rtl : TextDirection.ltr,
                        ),
                        Text(
                          AppStringsManager.getString(
                              _language, 'family_members'),
                          textDirection:
                              isRtl ? TextDirection.rtl : TextDirection.ltr,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// VERWENDUNGSBEISPIELE ZUSAMMENGEFASST:
// ============================================================
/*

1. BASIC IMPORT & NAVIGATION:
   
   import 'package:trusted_circle_demo/ui/family_profile_screen.dart';
   
   Navigator.push(
     context,
     MaterialPageRoute(builder: (_) => const FamilyProfileScreen()),
   );

2. MIT LOCALIZATION:
   
   import 'package:trusted_circle_demo/l10n/app_localizations_all.dart';
   
   String title = AppStringsManager.getString('de', 'family_profile_title');

3. RTL DETECTION:
   
   bool isRtl = AppStringsManager.isRtl('ar');
   
   Text(
     'Hello',
     textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
   )

4. IN STATEFULWIDGET:
   
   String _currentLanguage = 'de';
   String _t(String key) => AppStringsManager.getString(_currentLanguage, key);
   
   Text(_t('my_key'))

*/
