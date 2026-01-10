import 'package:flutter/material.dart';
import 'package:trusted_circle_demo/l10n/app_localizations.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final List<Map<String, dynamic>> _contacts = [
    {
      'name': 'Dr. Schmidt',
      'type': 'Kinderarzt',
      'phone': '+49 123 456789',
      'emergency': true,
      'icon': Icons.medical_services,
      'color': Colors.red,
    },
    {
      'name': 'Grundschule Nord',
      'type': 'Schule',
      'phone': '+49 123 987654',
      'emergency': false,
      'icon': Icons.school,
      'color': Colors.blue,
    },
    {
      'name': 'Oma Martha',
      'type': 'Familie',
      'phone': '+49 123 111222',
      'emergency': true,
      'icon': Icons.family_restroom,
      'color': Colors.purple,
    },
    {
      'name': 'Polizei',
      'type': 'Notruf',
      'phone': '110',
      'emergency': true,
      'icon': Icons.local_police,
      'color': Colors.orange,
    },
    {
      'name': 'Feuerwehr',
      'type': 'Notruf',
      'phone': '112',
      'emergency': true,
      'icon': Icons.fire_truck,
      'color': Colors.red,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final emergency = _contacts.where((c) => c['emergency'] as bool).toList();
    final regular = _contacts.where((c) => !(c['emergency'] as bool)).toList();
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [theme.colorScheme.primary.withOpacity(0.03), Colors.white],
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (emergency.isNotEmpty) ...[
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.red[700], size: 20),
                const SizedBox(width: 8),
                Text(
                  'Notfallkontakte',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.red[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...emergency.map((contact) => _buildContactCard(contact, theme, true)),
            const SizedBox(height: 24),
          ],
          if (regular.isNotEmpty) ...[
            Text(
              'Wichtige Kontakte',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),
            ...regular.map((contact) => _buildContactCard(contact, theme, false)),
          ],
        ],
      ),
    );
  }

  Widget _buildContactCard(Map<String, dynamic> contact, ThemeData theme, bool isEmergency) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isEmergency ? Colors.red[200]! : Colors.grey[200]!,
            width: isEmergency ? 2 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (contact['color'] as Color).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  contact['icon'] as IconData,
                  color: contact['color'] as Color,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contact['name'] as String,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      contact['type'] as String,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.phone, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          contact['phone'] as String,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.phone, color: theme.colorScheme.primary),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Rufe ${contact['name']} an...')),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
