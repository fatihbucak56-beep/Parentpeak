import 'package:flutter/material.dart';
import 'package:parentpeak/main.dart';

/// Ein Wrapper-Widget das jeden Widget-Baum mit Sprachänderungen verbindet
/// Nutze dies um alle Screens automatisch zu aktualisieren wenn die Sprache wechselt
class LanguageListener extends StatefulWidget {
  final Widget child;

  const LanguageListener({
    super.key,
    required this.child,
  });

  @override
  State<LanguageListener> createState() => _LanguageListenerState();
}

class _LanguageListenerState extends State<LanguageListener> {
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
        // Erzwinge einen Widget-Rebuild wenn die Sprache wechselt
      });
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
