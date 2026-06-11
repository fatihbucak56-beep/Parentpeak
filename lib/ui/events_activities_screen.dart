import 'package:flutter/material.dart';
import 'package:trusted_circle_demo/ui/create_event_screen.dart';
import 'package:trusted_circle_demo/ui/meetup_screen.dart';

class EventsActivitiesScreen extends StatelessWidget {
  const EventsActivitiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Events & Aktivitäten'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ActionCard(
            icon: Icons.groups_rounded,
            title: 'Aktivitäten entdecken',
            subtitle: 'Meetups ansehen und passende Treffs finden',
            color: const Color(0xFF0EA5A4),
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
            subtitle: 'Neues Familien-Event planen und teilen',
            color: const Color(0xFF8B5CF6),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateEventScreen()),
              );
            },
          ),
        ],
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
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withOpacity(0.25)),
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
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
        ),
      ),
    );
  }
}