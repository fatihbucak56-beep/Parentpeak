import 'package:flutter/material.dart';
import 'package:trusted_circle_demo/logic/auth_service.dart';
import 'package:trusted_circle_demo/logic/family_circle_service.dart';
import 'package:trusted_circle_demo/models/family_contact.dart';

class FamilyCircleScreen extends StatefulWidget {
  const FamilyCircleScreen({super.key});

  @override
  State<FamilyCircleScreen> createState() => _FamilyCircleScreenState();
}

class _FamilyCircleScreenState extends State<FamilyCircleScreen> {
  final _service = FamilyCircleService.instance;

  List<FamilyContact> _contacts = [];
  List<FamilyConnectionRequest> _requests = [];
  bool _isLoading = true;

  String get _currentUserId =>
      AuthService.instance.currentUser?.uid ?? 'host_demo_001';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final contacts = await _service.getConnectedContacts(userId: _currentUserId);
    final requests = await _service.getIncomingRequests(userId: _currentUserId);
    if (!mounted) return;
    setState(() {
      _contacts = contacts;
      _requests = requests;
      _isLoading = false;
    });
  }

  Future<void> _respond(FamilyConnectionRequest request, bool accept) async {
    await _service.respondToRequest(requestId: request.id, accept: accept);
    if (!mounted) return;
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(accept
            ? 'Kontaktanfrage angenommen'
            : 'Kontaktanfrage abgelehnt'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Familienkreis'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Text(
                      'Dein Familienkreis ist dein vertrauter Kontaktkreis. Private Events kannst du später nur mit diesen Kontakten oder gezielten Einladungen teilen.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF1E3A8A),
                        height: 1.35,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Kontaktanfragen',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  if (_requests.isEmpty)
                    const Text('Aktuell keine offenen Anfragen.')
                  else
                    ..._requests.map(
                      (r) => Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.person_add_alt_1_rounded),
                          ),
                          title: Text(r.fromDisplayName),
                          subtitle: const Text('möchte dich zum Familienkreis hinzufügen'),
                          trailing: Wrap(
                            spacing: 6,
                            children: [
                              IconButton(
                                tooltip: 'Ablehnen',
                                onPressed: () => _respond(r, false),
                                icon: const Icon(Icons.close_rounded),
                              ),
                              FilledButton(
                                onPressed: () => _respond(r, true),
                                child: const Text('Annehmen'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 18),
                  Text(
                    'Deine Kontakte',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  if (_contacts.isEmpty)
                    const Text('Noch keine Kontakte verbunden.')
                  else
                    ..._contacts.map(
                      (c) => Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.people_alt_rounded),
                          ),
                          title: Text(c.displayName),
                          subtitle: Text('${c.city} • ${c.childrenSummary}'),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
