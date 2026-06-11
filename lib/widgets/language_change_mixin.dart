import 'package:flutter/material.dart';
import 'package:trusted_circle_demo/main.dart';

/// Mixin für alle Screens um auf Sprachänderungen zu reagieren
mixin LanguageChangeMixin<T extends StatefulWidget> on State<T> {
  @override
  void initState() {
    super.initState();
    languageService.addListener(_rebuildOnLanguageChange);
  }

  @override
  void dispose() {
    languageService.removeListener(_rebuildOnLanguageChange);
    super.dispose();
  }

  void _rebuildOnLanguageChange() {
    if (mounted) {
      setState(() {
        // Erzwinge Rebuild wenn Sprache sich ändert
      });
    }
  }
}
