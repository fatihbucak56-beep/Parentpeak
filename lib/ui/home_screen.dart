import 'package:flutter/material.dart';
import 'package:trusted_circle_demo/main.dart';
import 'package:trusted_circle_demo/logic/auth_service.dart';
import 'package:trusted_circle_demo/ui/calendar_screen.dart';
import 'package:trusted_circle_demo/ui/events_activities_screen.dart';
import 'package:trusted_circle_demo/ui/event_invitations_screen.dart';
import 'package:trusted_circle_demo/ui/family_circle_screen.dart';
import 'package:trusted_circle_demo/ui/organization_screen.dart';
import 'package:trusted_circle_demo/ui/entwicklung_impulse_screen.dart';
import 'package:trusted_circle_demo/ui/parent_matching_screen.dart';
import 'package:trusted_circle_demo/ui/chat_screen.dart';
import 'package:trusted_circle_demo/ui/finance_budget_screen.dart';
import 'package:trusted_circle_demo/ui/kettenbrecher_dashboard.dart';
import 'package:trusted_circle_demo/ui/treasure_handover_screen.dart';
import 'package:trusted_circle_demo/l10n/app_localizations.dart';

class _FeatureAction {
  final String label;
  final String description;
  final IconData icon;
  final Color color;
  final WidgetBuilder builder;

  const _FeatureAction({
    required this.label,
    required this.description,
    required this.icon,
    required this.color,
    required this.builder,
  });
}

class HomeScreen extends StatefulWidget {
  final String? initialInviteInput;

  const HomeScreen({super.key, this.initialInviteInput});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _initialInviteHandled = false;

  @override
  void initState() {
    super.initState();
    languageService.addListener(_onLanguageChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openInitialInviteIfNeeded();
    });
  }

  @override
  void dispose() {
    languageService.removeListener(_onLanguageChanged);
    super.dispose();
  }

  void _openInitialInviteIfNeeded() {
    if (_initialInviteHandled) return;
    final input = widget.initialInviteInput?.trim();
    if (input == null || input.isEmpty || !mounted) return;

    _initialInviteHandled = true;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EventInvitationsScreen(initialInviteInput: input),
      ),
    );
  }


  void _onLanguageChanged() {
    if (mounted) {
      setState(() {
        // Erzwinge Rebuild wenn Sprache wechselt
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final viewportWidth = MediaQuery.sizeOf(context).width;
    final contentMaxWidth = viewportWidth >= 1400
      ? 1260.0
      : viewportWidth >= 1024
        ? 1120.0
        : double.infinity;
    final horizontalPadding = viewportWidth >= 1024 ? 24.0 : 20.0;
    final gridCrossAxisCount = viewportWidth >= 1220
      ? 4
      : viewportWidth >= 860
        ? 3
        : 2;
    final gridAspectRatio = viewportWidth >= 1220
      ? 1.42
      : viewportWidth >= 860
        ? 1.36
        : 1.38;

    final featureActions = <_FeatureAction>[
      _FeatureAction(
        label: 'Impulse & Entwicklung',
        description: 'Wochenimpuls und Entwicklung in einem Bereich',
        icon: Icons.auto_awesome_mosaic_rounded,
        color: const Color(0xFF0EA5A4),
        builder: (_) => const EntwicklungImpulseScreen(),
      ),
      _FeatureAction(
        label: 'Kalender',
        description: 'Termine und Familienplan',
        icon: Icons.calendar_month_rounded,
        color: const Color(0xFF2563EB),
        builder: (_) => const CalendarScreen(),
      ),
      _FeatureAction(
        label: 'Events & Aktivitäten',
        description: 'Events finden und selbst anbieten',
        icon: Icons.celebration_rounded,
        color: const Color(0xFF8B5CF6),
        builder: (_) => const EventsActivitiesScreen(),
      ),
      _FeatureAction(
        label: 'Familienkreis',
        description: 'Vertrauenskontakte verwalten und Einladungen steuern',
        icon: Icons.people_alt_rounded,
        color: const Color(0xFF4F46E5),
        builder: (_) => const FamilyCircleScreen(),
      ),
      _FeatureAction(
        label: l10n.t('treasureTileTitle', fallback: 'Kinder-Schatzkiste'),
        description:
            l10n.t('treasureDateOrSwap', fallback: 'Date oder Geister-Tausch'),
        icon: Icons.inventory_2_rounded,
        color: const Color(0xFF1E5CD7),
        builder: (_) => const TreasureHandoverScreen(),
      ),
      _FeatureAction(
        label: 'Eltern Match',
        description: 'Eltern finden fuer Playdates und Austausch',
        icon: Icons.diversity_3_rounded,
        color: const Color(0xFF0EA5A4),
        builder: (_) => const ParentMatchingScreen(),
      ),
      _FeatureAction(
        label: 'KI Elternberatung',
        description: 'Schnelle Hilfe und Tipps rund um Erziehung',
        icon: Icons.tips_and_updates_rounded,
        color: const Color(0xFF0284C7),
        builder: (_) => const ChatScreen(),
      ),
      _FeatureAction(
        label: 'Organisation',
        description: 'To-do und Einkauf in einem Bereich',
        icon: Icons.fact_check_rounded,
        color: const Color(0xFF16A34A),
        builder: (_) => const OrganizationScreen(),
      ),
      _FeatureAction(
        label: 'Essensplaner X',
        description: 'Guerilla-Kochen, Hub-Rotation und SOS',
        icon: Icons.restaurant_menu_rounded,
        color: const Color(0xFFF59E0B),
        builder: (_) => const KettenbrecherDashboard(),
      ),
      _FeatureAction(
        label: 'Finanzen & Budget',
        description: 'Ausgaben fair teilen und smarter sparen',
        icon: Icons.account_balance_wallet_rounded,
        color: const Color(0xFF1D4ED8),
        builder: (_) => const FinanceBudgetScreen(),
      ),
    ];

    final visibleGridActions = featureActions;

    final displayName = AuthService.instance.currentUser?.displayName.trim() ?? '';
    final familyGreeting = displayName.isEmpty
        ? 'Hallo Familie 👋'
        : 'Hallo Familie $displayName 👋';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: contentMaxWidth),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(horizontalPadding, 10, horizontalPadding, 8),
                    child: _buildHeroCard(theme, familyGreeting),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                    child: Container(
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.outline.withValues(alpha: 0),
                            theme.colorScheme.outline.withValues(alpha: 0.2),
                            theme.colorScheme.outline.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(horizontalPadding, 14, horizontalPadding, 24),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final action = visibleGridActions[index];
                        return _buildFeatureTile(
                          context,
                          title: action.label,
                          subtitle: action.description,
                          icon: action.icon,
                          color: action.color,
                          compact: true,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: action.builder),
                          ),
                        );
                      },
                      childCount: visibleGridActions.length,
                    ),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: gridCrossAxisCount,
                      mainAxisSpacing: 7,
                      crossAxisSpacing: 7,
                      childAspectRatio: gridAspectRatio,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard(ThemeData theme, String familyGreeting) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(alpha: 0.82),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.22),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Parentpeak',
            style: theme.textTheme.titleSmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
              fontFamily: 'SF Pro Rounded',
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    'assets/images/neue logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      familyGreeting,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.97),
                        fontWeight: FontWeight.w500,
                        height: 1.18,
                        letterSpacing: 0.15,
                        fontFamily: 'SF Pro Rounded',
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Alles Wichtige für euren Alltag.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Gemeinsam planen, teilen und verbunden bleiben.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                        height: 1.2,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required Color color,
    required IconData icon,
    bool compact = false,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compactTile =
                compact || constraints.maxWidth < 150 || constraints.maxHeight < 210;

            return Container(
              padding: EdgeInsets.all(compactTile ? 9 : 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color.withValues(alpha: 0.16),
                    color.withValues(alpha: 0.06),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: compactTile ? 28 : 42,
                    height: compactTile ? 28 : 42,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(compactTile ? 10 : 14),
                    ),
                    child: Icon(icon, color: Colors.white, size: compactTile ? 15 : 22),
                  ),
                  SizedBox(height: compactTile ? 4 : 8),
                  Text(
                    title,
                    maxLines: compactTile ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                    style: (compactTile
                            ? theme.textTheme.labelLarge
                            : theme.textTheme.titleMedium)
                        ?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: compactTile ? 12.5 : null,
                    ),
                  ),
                  SizedBox(height: compactTile ? 1 : 3),
                  Text(
                    subtitle,
                    style: (compactTile
                            ? theme.textTheme.bodySmall
                            : theme.textTheme.bodyMedium)
                        ?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: compactTile ? 1.2 : 1.3,
                      fontSize: compactTile ? 10.5 : null,
                    ),
                    maxLines: compactTile ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (!compactTile) ...[
                    const Spacer(),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Icon(Icons.arrow_forward_ios_rounded,
                          size: 14, color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
