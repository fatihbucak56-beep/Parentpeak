import 'package:flutter/material.dart';
import 'package:trusted_circle_demo/ui/create_event_screen.dart';
import 'package:trusted_circle_demo/ui/event_discover_screen.dart';
import 'package:trusted_circle_demo/ui/event_invitations_screen.dart';
import 'package:trusted_circle_demo/ui/meetup_screen.dart';

class EventsActivitiesScreen extends StatelessWidget {
  const EventsActivitiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Events & Aktivitäten')),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF3FAF9), Color(0xFFF7F8FE), Color(0xFFFFFAF2)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.78),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Alles für eure Familien-Aktivitäten',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Entdecke lokale Angebote, finde Aktivitäten in deiner Nähe und veröffentliche eigene Events.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _ActionCard(
              icon: Icons.auto_awesome_rounded,
              title: 'Aktivitäten entdecken',
              subtitle: 'Events, Theater, Kino und mehr in deiner Stadt finden',
              color: const Color(0xFF0EA5A4),
              badge: 'Empfohlen',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EventDiscoverScreen()),
                );
              },
            ),
            const SizedBox(height: 12),
            _ActionCard(
              icon: Icons.explore_rounded,
              title: 'Aktivitäten in der Nähe',
              subtitle: 'Öffentliche und private Aktivitäten nach Standort ansehen',
              color: const Color(0xFF2563EB),
              badge: 'Neu',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MeetupScreen()),
                );
              },
            ),
            const SizedBox(height: 12),
            _ActionCard(
              icon: Icons.add_circle_rounded,
              title: 'Event erstellen',
              subtitle: 'Neues Familien-Event planen und veröffentlichen',
              color: const Color(0xFFF59E0B),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateEventScreen()),
                );
              },
            ),
            const SizedBox(height: 12),
            _ActionCard(
              icon: Icons.mark_email_unread_rounded,
              title: 'Einladungen',
              subtitle: 'Event-Einladungen annehmen oder per Code beitreten',
              color: const Color(0xFF4F46E5),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EventInvitationsScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.1),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          if (badge != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                badge!,
                                style: TextStyle(
                                  color: color,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
