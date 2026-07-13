import 'package:flutter/material.dart';
import 'package:trusted_circle_demo/main.dart';

/// Ein Wrapper, der jeden Widget zwingt, sich neu zu rendern wenn die Sprache wechselt
class LanguageAwareWidget extends StatefulWidget {
  final Widget child;

  const LanguageAwareWidget({
    super.key,
    required this.child,
  });

  @override
  State<LanguageAwareWidget> createState() => _LanguageAwareWidgetState();
}

class _LanguageAwareWidgetState extends State<LanguageAwareWidget> {
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
      debugPrint('🔄 LanguageAwareWidget._onLanguageChanged() triggered!');
      debugPrint('   Current language: ${languageService.currentLanguage}');
      setState(() {
        // Erzwinge Rebuild
      });
      debugPrint('   setState() called, rebuilding child widget');
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
