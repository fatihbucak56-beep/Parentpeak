import 'package:flutter/material.dart';
import 'package:trusted_circle_demo/logic/auth_service.dart';
import 'package:trusted_circle_demo/logic/event_service.dart';
import 'package:trusted_circle_demo/models/meetup_event.dart';
import 'package:trusted_circle_demo/ui/event_detail_screen.dart';
import 'package:trusted_circle_demo/ui/create_event_screen.dart';

class MeetupScreen extends StatefulWidget {
  const MeetupScreen({super.key});

  @override
  State<MeetupScreen> createState() => _MeetupScreenState();
}

enum FeedVisibilityFilter { all, publicOnly, familyCircle, inviteOnly }

class _MeetupScreenState extends State<MeetupScreen> {
  final _eventService = EventService();
  List<MeetupEvent> _events = [];
  bool _isGridView = true;
  bool _isLoading = true;
  final List<AgeGroup> _selectedAgeGroups = [];
  FeedVisibilityFilter _visibilityFilter = FeedVisibilityFilter.all;
  static const double _viewerLatitude = 52.5200;
  static const double _viewerLongitude = 13.4050;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    try {
      final viewerUserId =
          AuthService.instance.currentUser?.uid ?? 'guest_user';
      final events = await _eventService.getDiscoverableEventsForUser(
        viewerUserId: viewerUserId,
        viewerLatitude: _viewerLatitude,
        viewerLongitude: _viewerLongitude,
        ageGroups: _selectedAgeGroups,
      );
      setState(() {
        _events = events;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Laden: $e')),
        );
      }
    }
  }

  void _filterByAgeGroup(AgeGroup ageGroup) {
    setState(() {
      if (_selectedAgeGroups.contains(ageGroup)) {
        _selectedAgeGroups.remove(ageGroup);
      } else {
        _selectedAgeGroups.add(ageGroup);
      }
    });
  }

  List<MeetupEvent> get _filteredEvents {
    final byAge = _selectedAgeGroups.isEmpty
        ? _events
        : _events
            .where((event) =>
                event.ageGroups.any((ag) => _selectedAgeGroups.contains(ag)))
            .toList();

    switch (_visibilityFilter) {
      case FeedVisibilityFilter.all:
        return byAge;
      case FeedVisibilityFilter.publicOnly:
        return byAge
            .where((e) => e.visibility == EventVisibility.publicNearby)
            .toList();
      case FeedVisibilityFilter.familyCircle:
        return byAge
            .where((e) => e.visibility == EventVisibility.familyCircle)
            .toList();
      case FeedVisibilityFilter.inviteOnly:
        return byAge
            .where((e) => e.visibility == EventVisibility.inviteOnly)
            .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aktivitäten & Treffen'),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateEventScreen()),
          ).then((_) => _loadEvents());
        },
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          color: Color(0xFF1D4ED8)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Öffentliche Events werden nach Standort geteilt. Zusätzlich gibt es Familienkreis- und Einladungs-Events.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: const Color(0xFF1E3A8A),
                                height: 1.3,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Filter-Chips für Altersgruppen
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                  child: Row(
                    children: AgeGroup.values
                        .map(
                          (ageGroup) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(_getAgeGroupLabel(ageGroup)),
                              selected: _selectedAgeGroups.contains(ageGroup),
                              onSelected: (_) => _filterByAgeGroup(ageGroup),
                              selectedColor: const Color(0xFFDBEAFE),
                              checkmarkColor: const Color(0xFF1D4ED8),
                              labelStyle: TextStyle(
                                color: _selectedAgeGroups.contains(ageGroup)
                                    ? const Color(0xFF1D4ED8)
                                    : null,
                                fontWeight: _selectedAgeGroups.contains(ageGroup)
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildVisibilityChip(
                          label: 'Alle',
                          selected: _visibilityFilter == FeedVisibilityFilter.all,
                          onTap: () =>
                              setState(() => _visibilityFilter = FeedVisibilityFilter.all),
                        ),
                        const SizedBox(width: 8),
                        _buildVisibilityChip(
                          label: 'Öffentlich',
                          selected:
                              _visibilityFilter == FeedVisibilityFilter.publicOnly,
                          onTap: () => setState(
                              () => _visibilityFilter = FeedVisibilityFilter.publicOnly),
                        ),
                        const SizedBox(width: 8),
                        _buildVisibilityChip(
                          label: 'Familienkreis',
                          selected:
                              _visibilityFilter == FeedVisibilityFilter.familyCircle,
                          onTap: () => setState(
                              () => _visibilityFilter = FeedVisibilityFilter.familyCircle),
                        ),
                        const SizedBox(width: 8),
                        _buildVisibilityChip(
                          label: 'Nur eingeladen',
                          selected:
                              _visibilityFilter == FeedVisibilityFilter.inviteOnly,
                          onTap: () => setState(
                              () => _visibilityFilter = FeedVisibilityFilter.inviteOnly),
                        ),
                      ],
                    ),
                  ),
                ),
                // Toggle zwischen Grid und List View
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_filteredEvents.length} Aktivitäten gefunden',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            _buildViewToggleButton(
                              icon: Icons.view_comfy,
                              selected: _isGridView,
                              onTap: () => setState(() => _isGridView = true),
                            ),
                            _buildViewToggleButton(
                              icon: Icons.list,
                              selected: !_isGridView,
                              onTap: () => setState(() => _isGridView = false),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Events Grid/List
                Expanded(
                  child: _filteredEvents.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.event_note, size: 64, color: Colors.grey[300]),
                              const SizedBox(height: 16),
                              Text(
                                'Keine Aktivitäten gefunden',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Passe die Altersgruppe an oder erstelle ein neues Event.',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey[500],
                                    ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : _isGridView
                          ? GridView.builder(
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 16,
                                crossAxisSpacing: 16,
                                childAspectRatio: 0.8,
                              ),
                              padding: const EdgeInsets.all(16),
                              itemCount: _filteredEvents.length,
                              itemBuilder: (context, index) =>
                                  _buildEventCard(_filteredEvents[index]),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _filteredEvents.length,
                              itemBuilder: (context, index) =>
                                  _buildEventListItem(_filteredEvents[index]),
                            ),
                )
              ],
            ),
    );
  }

  Widget _buildEventCard(MeetupEvent event) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventDetailScreen(event: event),
          ),
        );
      },
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event Foto
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  image: DecorationImage(
                    image: NetworkImage(event.photoUrl),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Stack(
                  children: [
                    // Category Badge
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _getCategoryLabel(event.category),
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    // Plätze verfügbar Badge
                    if (event.isFull)
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red[400],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'VOLL',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),

                    if (event.visibility != EventVisibility.publicNearby)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _getVisibilityBadge(event),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Event Info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 12, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '${event.eventDate.day}.${event.eventDate.month}. ${event.eventDate.hour.toString().padLeft(2, '0')}:${event.eventDate.minute.toString().padLeft(2, '0')}',
                        style:
                            TextStyle(fontSize: 10, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.people, size: 12, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '${event.currentParticipants}/${event.maxParticipants}',
                        style:
                            TextStyle(fontSize: 10, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewToggleButton({
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: selected ? Colors.white : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            icon,
            size: 18,
            color: selected ? Theme.of(context).primaryColor : Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildVisibilityChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: const Color(0xFFDBEAFE),
      labelStyle: TextStyle(
        color: selected ? const Color(0xFF1D4ED8) : null,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
      ),
    );
  }

  Widget _buildEventListItem(MeetupEvent event) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventDetailScreen(event: event),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: ListTile(
          leading: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
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
              if (event.visibility != EventVisibility.publicNearby)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    _getVisibilityDescription(event),
                    style: const TextStyle(fontSize: 10, color: Colors.black54),
                  ),
                ),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 12, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${event.eventDate.day}.${event.eventDate.month}. ${event.eventDate.hour.toString().padLeft(2, '0')}:${event.eventDate.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.people, size: 12, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${event.currentParticipants}/${event.maxParticipants}',
                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
          trailing: event.isFull
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'VOLL',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.red[700],
                    ),
                  ),
                )
              : Icon(
                  Icons.arrow_forward_ios,
                  size: 12,
                  color: Colors.grey[400],
                ),
        ),
      ),
    );
  }

  String _getCategoryLabel(EventCategory category) {
    const labels = {
      EventCategory.sports: 'Sport',
      EventCategory.outdoor: 'Outdoor',
      EventCategory.education: 'Bildung',
      EventCategory.arts: 'Kunst',
      EventCategory.socialGathering: 'Treffen',
      EventCategory.other: 'Sonstiges',
    };
    return labels[category] ?? 'Sonstiges';
  }

  String _getAgeGroupLabel(AgeGroup ageGroup) {
    const labels = {
      AgeGroup.infant: 'Baby (0-1)',
      AgeGroup.toddler: 'Kleinkind (1-3)',
      AgeGroup.preschool: 'Vorschule (3-5)',
      AgeGroup.elementary: 'Grundschule (6-12)',
      AgeGroup.teenager: 'Teenager (13+)',
      AgeGroup.mixed: 'Altersgemischt',
    };
    return labels[ageGroup] ?? '';
  }

  String _getVisibilityBadge(MeetupEvent event) {
    switch (event.visibility) {
      case EventVisibility.privateOnly:
        return 'PRIVAT';
      case EventVisibility.familyCircle:
        return 'KREIS';
      case EventVisibility.inviteOnly:
        return 'EINGELADEN';
      case EventVisibility.publicNearby:
        return '';
    }
  }

  String _getVisibilityDescription(MeetupEvent event) {
    switch (event.visibility) {
      case EventVisibility.privateOnly:
        return 'Privat · nur für den Host sichtbar';
      case EventVisibility.familyCircle:
        return 'Familienkreis · nur verbundene Kontakte';
      case EventVisibility.inviteOnly:
        return 'Nur eingeladen · individuelle Einladung';
      case EventVisibility.publicNearby:
        return '';
    }
  }
}
