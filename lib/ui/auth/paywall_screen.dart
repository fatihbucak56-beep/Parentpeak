import 'package:flutter/material.dart';
import 'package:trusted_circle_demo/logic/auth_service.dart';

class PaywallScreen extends StatelessWidget {
  final VoidCallback? onSubscribed;

  const PaywallScreen({super.key, this.onSubscribed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = AuthService.instance.currentUser;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              _buildHeader(theme, user),
              const SizedBox(height: 32),
              _buildFeatureList(theme),
              const SizedBox(height: 32),
              _buildPricingCards(context, theme),
              const SizedBox(height: 24),
              _buildMoneyBackBadge(theme),
              const SizedBox(height: 32),
              _buildContinueFreely(context, theme),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, ParentUser? user) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [theme.colorScheme.primary, theme.colorScheme.tertiary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.28),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.workspace_premium_rounded,
              color: Colors.white, size: 42),
        ),
        const SizedBox(height: 20),
        Text(
          'Parentpeak Premium',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          user != null
              ? 'Deine 14-Tage-Testphase ist abgelaufen.\nWähle ein Abo um weiterzumachen.'
              : 'Schalte alle Funktionen frei.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFeatureList(ThemeData theme) {
    final features = [
      (Icons.wb_sunny_rounded, 'Wochenimpuls', 'Jede Woche neue Eltern-Tipps'),
      (Icons.checklist_rtl_rounded, 'Entwicklungsschema', '0–18 Jahre, alle Phasen'),
      (Icons.chat_bubble_rounded, 'KI-Elternberatung', 'Antworten rund um die Uhr'),
      (Icons.calendar_month_rounded, 'Familienkalender', 'Termine für die ganze Familie'),
      (Icons.diversity_3_rounded, 'Eltern-Matching', 'Gleichgesinnte Eltern finden'),
      (Icons.celebration_rounded, 'Events & Aktivitäten', 'Lokale Meetups entdecken'),
    ];

    return Column(
      children: features.map((f) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(f.$1,
                    color: theme.colorScheme.onPrimaryContainer, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(f.$2,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    Text(f.$3,
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
              Icon(Icons.check_circle_rounded,
                  color: theme.colorScheme.primary, size: 20),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPricingCards(BuildContext context, ThemeData theme) {
    return Column(
      children: [
        _PricingCard(
          label: 'Jährlich',
          price: '29,99 €',
          subline: '2,50 € / Monat',
          badge: 'Beliebt · 37% Ersparnis',
          isPrimary: true,
          onTap: () => _activatePremium(context),
        ),
        const SizedBox(height: 12),
        _PricingCard(
          label: 'Monatlich',
          price: '3,99 €',
          subline: 'monatlich kündbar',
          onTap: () => _activatePremium(context),
        ),
      ],
    );
  }

  Future<void> _activatePremium(BuildContext context) async {
    // Stub: In Produktion hier In-App Purchase Flow starten
    await AuthService.instance.activatePremium();
    onSubscribed?.call();
    if (context.mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  Widget _buildMoneyBackBadge(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.verified_user_outlined,
              color: theme.colorScheme.onSurfaceVariant, size: 18),
          const SizedBox(width: 8),
          Text(
            '30 Tage Geld-zurück-Garantie · Jederzeit kündbar',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContinueFreely(BuildContext context, ThemeData theme) {
    return TextButton(
      onPressed: () => Navigator.of(context).pop(),
      child: Text(
        'Später entscheiden',
        style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
      ),
    );
  }
}

// ─── Pricing Card ─────────────────────────────────────────────────────────────

class _PricingCard extends StatelessWidget {
  final String label;
  final String price;
  final String subline;
  final String? badge;
  final bool isPrimary;
  final VoidCallback onTap;

  const _PricingCard({
    required this.label,
    required this.price,
    required this.subline,
    required this.onTap,
    this.badge,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isPrimary
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isPrimary
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant,
            width: isPrimary ? 2 : 1,
          ),
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (badge != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        badge!,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Text(label,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isPrimary
                            ? theme.colorScheme.onPrimaryContainer
                            : null,
                      )),
                  Text(subline,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      )),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  price,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: isPrimary ? theme.colorScheme.primary : null,
                  ),
                ),
                Text(
                  isPrimary ? '/ Jahr' : '/ Monat',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
