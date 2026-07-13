import 'package:flutter/material.dart';
import 'package:trusted_circle_demo/main.dart';

/// InheritedWidget um Sprache durch den Widget-Baum zu propagieren
class LanguageProvider extends InheritedWidget {
  final String currentLanguage;
  final VoidCallback? onLanguageChanged;

  const LanguageProvider({
    super.key,
    required this.currentLanguage,
    this.onLanguageChanged,
    required super.child,
  });

  static LanguageProvider? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<LanguageProvider>();
  }

  @override
  bool updateShouldNotify(LanguageProvider oldWidget) {
    debugPrint(
        '🔔 LanguageProvider.updateShouldNotify() - old: ${oldWidget.currentLanguage}, new: $currentLanguage');
    return oldWidget.currentLanguage != currentLanguage;
  }
}

/// StatefulWidget Wrapper um LanguageProvider zu managen
class LanguageProviderWrapper extends StatefulWidget {
  final Widget child;

  const LanguageProviderWrapper({
    super.key,
    required this.child,
  });

  @override
  State<LanguageProviderWrapper> createState() => _LanguageProviderWrapperState();
}

class _LanguageProviderWrapperState extends State<LanguageProviderWrapper> {
  late String _currentLanguage;

  @override
  void initState() {
    super.initState();
    _currentLanguage = languageService.currentLanguage;
    debugPrint(
        '✅ LanguageProviderWrapper.initState() - currentLanguage: $_currentLanguage');
    languageService.addListener(_onLanguageChanged);
  }

  @override
  void dispose() {
    languageService.removeListener(_onLanguageChanged);
    super.dispose();
  }

  void _onLanguageChanged() {
    debugPrint('🔄 LanguageProviderWrapper._onLanguageChanged() triggered');
    debugPrint('   Old: $_currentLanguage, New: ${languageService.currentLanguage}');
    setState(() {
      _currentLanguage = languageService.currentLanguage;
    });
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🏗️  LanguageProviderWrapper.build() - language: $_currentLanguage');
    return LanguageProvider(
      currentLanguage: _currentLanguage,
      child: widget.child,
    );
  }
}
