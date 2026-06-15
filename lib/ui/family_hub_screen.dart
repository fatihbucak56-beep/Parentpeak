import 'package:flutter/material.dart';
import 'package:trusted_circle_demo/models/trusted_device.dart';
import 'package:trusted_circle_demo/ui/calendar_screen.dart';
import 'package:trusted_circle_demo/ui/family_circle_screen.dart';
import 'package:trusted_circle_demo/ui/organization_screen.dart';
import 'package:trusted_circle_demo/ui/profile_safety_screen.dart';
import 'package:trusted_circle_demo/ui/weekly_planner_screen.dart';

class FamilyHubScreen extends StatelessWidget {
  const FamilyHubScreen({
    super.key,
    required this.devices,
    required this.onRevoke,
  });

  final List<TrustedDevice> devices;
  final Future<bool> Function(String deviceUuid, String deviceName) onRevoke;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final actions = <_HubAction>[
      _HubAction(
        title: 'Kalender & Erinnerungen',
        subtitle: 'Termine planen und smart erinnern lassen',
        icon: Icons.event_note_rounded,
        color: const Color(0xFF2563EB),
        builder: (_) => const CalendarScreen(),
      ),
      _HubAction(
        title: 'Organisation',
        subtitle: 'To-do und Einkauf in einem klaren Flow',
        icon: Icons.fact_check_rounded,
        color: const Color(0xFF16A34A),
        builder: (_) => const OrganizationScreen(),
      ),
      _HubAction(
        title: 'Familienkreis',
        subtitle: 'Kontakte verwalten und Einladungen steuern',
        icon: Icons.groups_rounded,
        color: const Color(0xFF7C3AED),
        builder: (_) => const FamilyCircleScreen(),
      ),
      _HubAction(
        title: 'Wochenplan',
        subtitle: 'Mahlzeiten und Familienmomente im Blick',
        icon: Icons.view_week_rounded,
        color: const Color(0xFFEA580C),
        builder: (_) => const WeeklyPlannerScreen(),
      ),
      _HubAction(
        title: 'Profil & Sicherheit',
        subtitle: 'Modern, klar und fokussiert auf Familie und Schutz',
        icon: Icons.shield_rounded,
        color: const Color(0xFF0EA5A4),
        builder: (_) => ProfileSafetyScreen(
          devices: devices,
          onRevoke: onRevoke,
        ),
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('FamilienHub'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1D4ED8), Color(0xFF4F46E5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1D4ED8).withValues(alpha: 0.22),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.nest_cam_wired_stand_rounded,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Euer Familien-Nest',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Alle Kernbereiche fuer den Familienalltag an einem Ort: klar, schnell und stressfrei.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.92),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: actions.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.18,
            ),
            itemBuilder: (context, index) {
              final action = actions[index];
              return _FamilyHubCard(action: action);
            },
          ),
        ],
      ),
    );
  }
}

class _HubAction {
  const _HubAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.builder,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final WidgetBuilder builder;
}

class _FamilyHubCard extends StatelessWidget {
  const _FamilyHubCard({required this.action});

  final _HubAction action;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(builder: action.builder));
      },
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: action.color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(action.icon, color: action.color),
            ),
            const Spacer(),
            Text(
              action.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                height: 1.15,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              action.subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF475569),
                fontSize: 12,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
