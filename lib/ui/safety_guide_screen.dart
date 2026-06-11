import 'package:flutter/material.dart';

class SafetyGuideScreen extends StatefulWidget {
  const SafetyGuideScreen({super.key});

  @override
  State<SafetyGuideScreen> createState() => _SafetyGuideScreenState();
}

class _SafetyGuideScreenState extends State<SafetyGuideScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sicherheits-Guide'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.shield, color: Colors.green[700], size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Deine Sicherheit ist unsere Priorität!',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Vor dem Treffen
            _buildSection(
              context,
              title: 'Vor dem Treffen',
              icon: Icons.checklist,
              items: [
                'Wähle einen öffentlichen und gut sichtbaren Treffpunkt',
                'Informiere vertrauenswürdige Personen über Ort und Zeit',
                'Prüfe das Wetter und packe angemessen',
                'Vereinbare ein Erkennungszeichen mit anderen Eltern',
                'Aktiviere dein Handy-Tracking oder teile deinen Standort',
              ],
            ),
            const SizedBox(height: 20),

            // Während des Treffens
            _buildSection(
              context,
              title: 'Während des Treffens',
              icon: Icons.location_on,
              items: [
                'Bleibe in der Nähe deiner Kinder und beobachte sie',
                'Baue eine Vertrauensbasis mit anderen Eltern auf',
                'Teile deine Kontaktdaten nur mit bestätigten Teilnehmern',
                'Nutze den Event-Chat nur für organisatorische Inhalte',
                'Dokumentiere Sicherheitsbedenken sofort',
              ],
            ),
            const SizedBox(height: 20),

            // Chat-Sicherheit
            _buildSection(
              context,
              title: 'Sicher im Chat kommunizieren',
              icon: Icons.message,
              items: [
                'Gib niemals die vollständige Adresse im Chat preis',
                'Vermeide die Freigabe persönlicher Informationen',
                'Nutze den Chat-Report-Button bei unangemessenem Verhalten',
                'Speichere keine Nachrichten mit persönlichen Daten ab',
                'Lösche alte Chats regelmäßig',
              ],
            ),
            const SizedBox(height: 20),

            // Warnsignale
            _buildDangerSection(
              context,
              title: 'Warnsignale - Melde verdächtiges Verhalten',
              items: [
                'Unerwünschte Aufforderungen zu privaten Treffen',
                'Anfragen nach persönlichen Informationen',
                'Unangemessene Bilder oder Inhalte',
                'Druck zur Geheimhaltung',
                'Verdächtige Fragen zu deinen Kindern',
              ],
            ),
            const SizedBox(height: 20),

            // Notfall-Hotline
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.emergency, color: Colors.red[700], size: 24),
                      const SizedBox(width: 12),
                      Text(
                        'Im Notfall',
                        style: TextStyle(
                          color: Colors.red[700],
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Polizei: 110',
                    style: TextStyle(
                      color: Colors.red[700],
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Notarzt: 112',
                    style: TextStyle(
                      color: Colors.red[700],
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Kinderschutz-Hotline: 0800-1110550',
                    style: TextStyle(
                      color: Colors.red[700],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Bestätigung
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Sicherheits-Guide gelesen und verstanden'),
                    ),
                  );
                  Navigator.pop(context);
                },
                child: const Text('Ich verstehe diese Richtlinien'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<String> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Theme.of(context).primaryColor, size: 24),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Column(
          children: items
              .map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Colors.green[600],
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(item),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildDangerSection(
    BuildContext context, {
    required String title,
    required List<String> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.warning, color: Colors.orange[700], size: 24),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.orange[700],
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Column(
          children: items
              .map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.warning,
                        color: Colors.orange[600],
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item,
                          style: TextStyle(color: Colors.orange[900]),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
