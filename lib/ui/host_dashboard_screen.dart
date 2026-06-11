import 'package:flutter/material.dart';
import 'package:trusted_circle_demo/logic/event_service.dart';
import 'package:trusted_circle_demo/logic/participation_service.dart';
import 'package:trusted_circle_demo/models/meetup_event.dart';
import 'package:trusted_circle_demo/models/event_participation.dart';

class HostDashboardScreen extends StatefulWidget {
  const HostDashboardScreen({super.key});

  @override
  State<HostDashboardScreen> createState() => _HostDashboardScreenState();
}

class _HostDashboardScreenState extends State<HostDashboardScreen> {
  final _eventService = EventService();
  final _participationService = ParticipationService();

  static const String _currentHostId = 'host_demo_001';

  List<MeetupEvent> _hostedEvents = [];
  List<EventParticipation> _pendingRequests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      final events = await _eventService.getEvents();
      final myEvents =
          events.where((e) => e.hosterId == _currentHostId).toList();

      final requests = await _eventService.getPendingRequestsForHost(_currentHostId);

      setState(() {
        _hostedEvents = myEvents;
        _pendingRequests = requests;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e')),
        );
      }
    }
  }

  Future<void> _approveRequest(String requestId) async {
    try {
      await _participationService.approveParticipation(requestId);
      setState(() {
        _pendingRequests.removeWhere((r) => r.id == requestId);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Anfrage genehmigt!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e')),
        );
      }
    }
  }

  Future<void> _declineRequest(String requestId) async {
    try {
      await _participationService.declineParticipation(requestId);
      setState(() {
        _pendingRequests.removeWhere((r) => r.id == requestId);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Anfrage abgelehnt')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mein Host-Dashboard'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Statistiken
                  _buildStatsSection(context),
                  const SizedBox(height: 24),

                  // Ausstehende Anfragen
                  _buildPendingRequestsSection(context),
                  const SizedBox(height: 24),

                  // Meine Aktivitäten
                  _buildMyEventsSection(context),
                ],
              ),
            ),
    );
  }

  Widget _buildStatsSection(BuildContext context) {
    int totalParticipants = 0;
    for (final event in _hostedEvents) {
      totalParticipants += event.currentParticipants;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Statistiken',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                icon: Icons.event,
                label: 'Aktivitäten',
                value: _hostedEvents.length.toString(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context,
                icon: Icons.people,
                label: 'Teilnehmer',
                value: totalParticipants.toString(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context,
                icon: Icons.schedule,
                label: 'Ausstehend',
                value: _pendingRequests.length.toString(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: Theme.of(context).primaryColor, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingRequestsSection(BuildContext context) {
    if (_pendingRequests.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Ausstehende Anfragen',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _pendingRequests.length.toString(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.amber[900],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Column(
          children: _pendingRequests
              .map((request) => _buildRequestCard(context, request))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildRequestCard(
      BuildContext context, EventParticipation request) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nutzer: ${request.userId}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Angefordert: ${request.requestedAt.day}.${request.requestedAt.month}.${request.requestedAt.year}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _declineRequest(request.id),
                    child: const Text('Ablehnen'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _approveRequest(request.id),
                    child: const Text('Genehmigen'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyEventsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Meine Aktivitäten',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        if (_hostedEvents.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                'Du hast noch keine Aktivitäten erstellt',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          )
        else
          Column(
            children: _hostedEvents
                .map((event) => _buildEventCard(context, event))
                .toList(),
          ),
      ],
    );
  }

  Widget _buildEventCard(BuildContext context, MeetupEvent event) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            image: DecorationImage(
              image: NetworkImage(event.photoUrl),
              fit: BoxFit.cover,
            ),
          ),
        ),
        title: Text(event.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 12, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${event.eventDate.day}.${event.eventDate.month}.',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
                const SizedBox(width: 12),
                Icon(Icons.people, size: 12, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${event.currentParticipants}/${event.maxParticipants}',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: event.status == EventStatus.active
                ? Colors.green[100]
                : Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            event.status == EventStatus.active ? 'AKTIV' : 'BEENDET',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: event.status == EventStatus.active
                  ? Colors.green[700]
                  : Colors.grey[700],
            ),
          ),
        ),
      ),
    );
  }
}
