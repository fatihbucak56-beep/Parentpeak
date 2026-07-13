import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageService extends ChangeNotifier {
  String _currentLanguage = 'de';
  bool _initialized = false;

  String get currentLanguage => _currentLanguage;
  bool get initialized => _initialized;

  LanguageService() {
    // Lade synchron wenn möglich, sonst asynchron
    _initPrefs();
  }

  void _initPrefs() {
    SharedPreferences.getInstance().then((prefs) {
      final saved = prefs.getString('selected_language');
      if (saved != null && saved.isNotEmpty) {
        _currentLanguage = saved;
        debugPrint('✅ Sprache async geladen: $_currentLanguage');
      } else {
        _currentLanguage = 'de';
        debugPrint('⚠️ Keine gespeicherte Sprache, verwende: de');
      }
      _initialized = true;
      notifyListeners();
    }).catchError((e) {
      debugPrint('❌ Fehler beim Laden SharedPreferences: $e');
      _currentLanguage = 'de';
      _initialized = true;
      notifyListeners();
    });
  }

  Future<void> setLanguage(String languageCode) async {
    if (!_initialized) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selected_language', languageCode);
      _currentLanguage = languageCode;
      debugPrint('✅ Sprache SYNCHRON gespeichert und gesetzt: $languageCode');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Fehler beim Speichern der Sprache: $e');
    }
  }
}
