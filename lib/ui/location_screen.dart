import 'package:flutter/material.dart';
import 'package:trusted_circle_demo/l10n/app_localizations.dart';
import 'package:trusted_circle_demo/widgets/language_change_mixin.dart';

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> with LanguageChangeMixin<LocationScreen> {
  final List<Map<String, dynamic>> _familyMembers = [
    {
      'name': 'Mama',
      'location': 'Zuhause',
      'lastUpdate': DateTime.now().subtract(const Duration(minutes: 5)),
      'battery': 85,
      'icon': Icons.person,
      'color': Colors.purple,
    },
    {
      'name': 'Papa',
      'location': 'Arbeit',
      'lastUpdate': DateTime.now().subtract(const Duration(minutes: 15)),
      'battery': 62,
      'icon': Icons.person_outline,
      'color': Colors.blue,
    },
    {
      'name': 'Leon',
      'location': 'Schule',
      'lastUpdate': DateTime.now().subtract(const Duration(minutes: 30)),
      'battery': 45,
      'icon': Icons.child_care,
      'color': Colors.green,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            theme.colorScheme.primary.withOpacity(0.03),
            theme.brightness == Brightness.dark ? Colors.grey[900]! : Colors.white
          ],
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey[200]!, width: 1),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.map_outlined, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Familien-Standorte',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.map, size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 8),
                          Text(
                            'Karte wird geladen...',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Familienmitglieder',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 12),
          ..._familyMembers.map((member) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey[200]!, width: 1),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: (member['color'] as Color).withOpacity(0.2),
                      child: Icon(
                        member['icon'] as IconData,
                        color: member['color'] as Color,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            member['name'] as String,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text(
                                member['location'] as String,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.access_time, size: 12, color: Colors.grey[500]),
                              const SizedBox(width: 4),
                              Text(
                                'vor ${DateTime.now().difference(member['lastUpdate'] as DateTime).inMinutes} Min',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[500],
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getBatteryColor(member['battery'] as int).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.battery_full,
                                size: 14,
                                color: _getBatteryColor(member['battery'] as int),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${member['battery']}%',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: _getBatteryColor(member['battery'] as int),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          )),
        ],
      ),
    );
  }

  Color _getBatteryColor(int battery) {
    if (battery > 60) return Colors.green;
    if (battery > 30) return Colors.orange;
    return Colors.red;
  }
}
