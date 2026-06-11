import 'package:flutter/material.dart';
import 'package:trusted_circle_demo/main.dart';
import 'package:trusted_circle_demo/l10n/app_localizations_all.dart';
import 'package:trusted_circle_demo/ui/meetup_screen.dart';
import 'package:trusted_circle_demo/ui/marketplace_screen.dart';
import 'package:trusted_circle_demo/ui/todo_screen.dart';
import 'package:trusted_circle_demo/ui/shopping_screen.dart';
import 'package:trusted_circle_demo/ui/photos_screen.dart';
import 'package:trusted_circle_demo/ui/contacts_screen.dart';
import 'package:trusted_circle_demo/ui/calendar_screen.dart';
import 'package:trusted_circle_demo/ui/location_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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

  String _t(String key) {
    return AppStringsManager.getString(languageService.currentLanguage, key);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final hour = now.hour;

    String greeting = _t('greeting_morning');
    if (hour >= 12 && hour < 18) {
      greeting = _t('greeting_afternoon');
    } else if (hour >= 18) {
      greeting = _t('greeting_evening');
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue[300]!,
              Colors.indigo[400]!,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo und Greeting
                  Center(
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Image.asset(
                            'assets/images/logo.png',
                            width: 120,
                            height: 120,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.family_restroom,
                                size: 60,
                                color: theme.colorScheme.primary,
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          '$greeting${_t('greeting_family')}',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.brightness == Brightness.dark
                                ? Colors.grey[300]
                                : Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    _t('what_today'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.brightness == Brightness.dark
                          ? Colors.grey[300]
                          : Colors.grey[700],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildFeatureCard(
                    context,
                    title: _t('activities_title'),
                    subtitle: _t('activities_subtitle'),
                    color: const Color(0xFF10B981),
                    icon: Icons.groups,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MeetupScreen()),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 🛍️ Marktplatz Button
                  _buildFeatureCard(
                    context,
                    title: 'Marktplatz',
                    subtitle: 'Nachhilfe, Betreuung & Kaufen/Verkaufen',
                    color: const Color(0xFF6366F1),
                    icon: Icons.shopping_bag_rounded,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MarketplaceScreen()),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _t('all_features'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.brightness == Brightness.dark
                          ? Colors.grey[300]
                          : Colors.grey[700],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    children: [
                      _buildSmallCard(
                        context,
                        icon: Icons.check_box_rounded,
                        title: _t('todo'),
                        color: const Color(0xFF00BFA5),
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const TodoScreen())),
                      ),
                      _buildSmallCard(
                        context,
                        icon: Icons.shopping_cart_rounded,
                        title: _t('shopping'),
                        color: const Color(0xFFFF6B9D),
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const ShoppingScreen())),
                      ),
                      _buildSmallCard(
                        context,
                        icon: Icons.photo_library_rounded,
                        title: _t('photos'),
                        color: const Color(0xFFFFC107),
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const PhotosScreen())),
                      ),
                      _buildSmallCard(
                        context,
                        icon: Icons.contact_phone_rounded,
                        title: _t('contacts'),
                        color: const Color(0xFFE91E63),
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const ContactsScreen())),
                      ),
                      _buildSmallCard(
                        context,
                        icon: Icons.calendar_month_rounded,
                        title: _t('calendar'),
                        color: const Color(0xFF2196F3),
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const CalendarScreen())),
                      ),
                      _buildSmallCard(
                        context,
                        icon: Icons.location_on_rounded,
                        title: _t('location'),
                        color: const Color(0xFFFF9800),
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const LocationScreen())),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      6,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 5),
                        width: index == 0 ? 28 : 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: index == 0
                              ? theme.colorScheme.primary
                              : Colors.grey[300],
                          borderRadius: BorderRadius.circular(5),
                          boxShadow: index == 0
                              ? [
                                  BoxShadow(
                                    color: theme.colorScheme.primary
                                        .withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : [],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required Color color,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: Colors.white, size: 32),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.92),
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          border: Border.all(color: color.withOpacity(0.2), width: 1.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: Colors.white, size: 28),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
