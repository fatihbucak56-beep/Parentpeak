import 'package:flutter/material.dart';
import 'package:trusted_circle_demo/main.dart';

/// Mixin für State-Klassen, die auf Sprachänderungen reagieren sollen
mixin LanguageAwareMixin<T extends StatefulWidget> on State<T> {
  @override
  void initState() {
    super.initState();
    languageService.addListener(_onLanguageChanged);
  }

  @override
  void dispose() {
    languageService.removeListener(_onLanguageChanged);
    super.dispose();
  }

  void _onLanguageChanged() {
    if (mounted) {
      setState(() {
        // Erzwinge Rebuild wenn Sprache wechselt
      });
    }
  }
}
