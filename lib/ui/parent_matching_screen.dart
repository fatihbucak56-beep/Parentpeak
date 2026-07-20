import 'dart:math';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:parentpeak/logic/auth_service.dart';
import 'package:parentpeak/logic/backend_service_factory.dart';
import 'package:parentpeak/logic/parent_matching_backend_service.dart';
import 'package:parentpeak/ui/match_conversation_screen.dart';

class ParentMatchingScreen extends StatefulWidget {
  const ParentMatchingScreen({
    super.key,
    this.openNewConnectionsOnOpen = false,
  });

  final bool openNewConnectionsOnOpen;

  @override
  State<ParentMatchingScreen> createState() => _ParentMatchingScreenState();
}

class _ParentMatchingScreenState extends State<ParentMatchingScreen> {
  static const String _storageKey = 'parent_matching.v1';
  static const Set<String> _defaultMyInterests = {
    'Bildung',
    'Spielplatz',
    'Familienzeit',
    'Outdoor',
    'Gesundheit'
  };
  static const Set<String> _defaultMyLanguages = {'Deutsch', 'Englisch'};
  static const Set<String> _defaultMyValues = {
    'Gewaltfrei',
    'Respekt',
    'Inklusion',
    'Empathie'
  };
  static const Map<String, (double, double)> _cityCenters = {
    'Berlin': (52.520008, 13.404954),
    'Koeln': (50.937531, 6.960279),
    'Hamburg': (53.551086, 9.993682),
    'Muenchen': (48.137154, 11.576124),
    'Frankfurt': (50.110924, 8.682127),
  };

  final ParentMatchingBackendService _service =
      BackendServiceFactory.createParentMatchingService();
  final List<_ParentProfile> _allProfiles = [];
  final List<_ParentProfile> _likedProfiles = [];
  final List<_ParentProfile> _matchedProfiles = [];
  final Set<String> _blockedProfileIds = {};
  final Set<String> _reportedProfileIds = {};

  final Set<String> _interestFilter = {};
  final Set<String> _languageFilter = {};
  final Set<String> _valuesFilter = {};
  final Set<String> _familyFormFilter = {};
  final Set<String> _childAgeFilter = {};
  final Set<String> _myInterests = {..._defaultMyInterests};
  final Set<String> _myLanguages = {..._defaultMyLanguages};
  final Set<String> _myValues = {..._defaultMyValues};
  final Set<String> _seenMatchedProfileIds = {};
  final Set<String> _newlyConfirmedProfileIds = {};

  double _maxDistanceKm = 20;
  String _homeCity = 'Berlin';
  int _newConfirmedSinceLastVisit = 0;

  int _currentIndex = 0;
  bool _isRestoring = true;
  bool _requiresProfileSetup = false;
  bool _isSavingProfile = false;
  final TextEditingController _profileNameController = TextEditingController();
  int _profileAge = 33;
  String _profileFamilyForm = 'Kernfamilie';

  String? get _currentUserId {
    final value = AuthService.instance.currentUser?.uid.trim();
    if (value == null || value.isEmpty) return null;
    return value;
  }

  String get _effectiveUserId => _currentUserId ?? 'local-parent-user';

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _profileNameController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final profileReady = await _ensureMyProfileExists();
    if (!profileReady) return;

    await _loadProfiles();
    await _restoreState();
    await _refreshConnectionsFromBackend(
      announce: !widget.openNewConnectionsOnOpen,
    );

    if (widget.openNewConnectionsOnOpen && _newConfirmedSinceLastVisit > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _openNewConnectionsSheet();
      });
    }
  }

  Future<bool> _ensureMyProfileExists() async {
    final profile = await _service.fetchMyProfile(userId: _effectiveUserId);
    if (profile != null) {
      if (_profileNameController.text.trim().isEmpty) {
        _profileNameController.text = (profile['name'] ?? '').toString();
      }
      return true;
    }

    if (!mounted) return false;
    _profileNameController.text =
        AuthService.instance.currentUser?.displayName.trim().isNotEmpty == true
            ? AuthService.instance.currentUser!.displayName.trim()
            : 'Elternteil';
    setState(() {
      _requiresProfileSetup = true;
      _isRestoring = false;
    });
    return false;
  }

  Future<void> _loadProfiles() async {
    try {
      // Use new smart matching algorithm
      final matchResults = await _service.findMatches(userId: _effectiveUserId);

      // Convert MatchResult objects to internal _ParentProfile format
      final profiles = matchResults.map((result) {
        final profile = result.profile;
        // Convert breakdown map values to doubles
        final breakdownAsDoubles = result.breakdown.map(
          (key, value) =>
              MapEntry(key, (value is num) ? value.toDouble() : 0.0),
        );
        final age = profile.age;
        final familyForm = profile.familyForm;
        return _ParentProfile(
          id: profile.id,
          name: profile.name ?? 'Unbekannt',
          age: (age != null) ? age : 30,
          city: profile.city,
          bio: 'Matching-Score: ${result.score.toStringAsFixed(0)}%',
          interests: profile.interests,
          languages: profile.languages,
          valuesFocus: profile.valuesFocus,
          familyForm: (familyForm != null) ? familyForm : 'Familie',
          childAges: profile.childAges,
          latitude: profile.latitude,
          longitude: profile.longitude,
          score: result.score as double?,
          breakdown: breakdownAsDoubles,
        );
      }).toList();

      if (!mounted) return;
      setState(() {
        _allProfiles
          ..clear()
          ..addAll(profiles);
      });
    } catch (e) {
      // Fallback for errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Smart Matching konnte nicht geladen werden: $e'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _restoreState() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      if (!mounted) return;
      setState(() => _isRestoring = false);
      return;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        if (!mounted) return;
        setState(() => _isRestoring = false);
        return;
      }

      final likedIds =
          (decoded['likedIds'] as List?)?.map((e) => e.toString()).toSet() ??
              <String>{};
      final matchedIds =
          (decoded['matchedIds'] as List?)?.map((e) => e.toString()).toSet() ??
              <String>{};
      final blockedIds =
          (decoded['blockedIds'] as List?)?.map((e) => e.toString()).toSet() ??
              <String>{};
      final reportedIds =
          (decoded['reportedIds'] as List?)?.map((e) => e.toString()).toSet() ??
              <String>{};

      if (!mounted) return;
      setState(() {
        _likedProfiles
          ..clear()
          ..addAll(_allProfiles.where((p) => likedIds.contains(p.id)));
        _matchedProfiles
          ..clear()
          ..addAll(_allProfiles.where((p) => matchedIds.contains(p.id)));
        _seenMatchedProfileIds
          ..clear()
          ..addAll((decoded['seenMatchedProfileIds'] as List?)
                  ?.map((e) => e.toString())
                  .toSet() ??
              matchedIds);
        _blockedProfileIds
          ..clear()
          ..addAll(blockedIds);
        _reportedProfileIds
          ..clear()
          ..addAll(reportedIds);

        _interestFilter
          ..clear()
          ..addAll((decoded['interestFilter'] as List?)
                  ?.map((e) => e.toString())
                  .toSet() ??
              <String>{});
        _languageFilter
          ..clear()
          ..addAll((decoded['languageFilter'] as List?)
                  ?.map((e) => e.toString())
                  .toSet() ??
              <String>{});
        _valuesFilter
          ..clear()
          ..addAll((decoded['valuesFilter'] as List?)
                  ?.map((e) => e.toString())
                  .toSet() ??
              <String>{});
        _familyFormFilter
          ..clear()
          ..addAll((decoded['familyFormFilter'] as List?)
                  ?.map((e) => e.toString())
                  .toSet() ??
              <String>{});
        _childAgeFilter
          ..clear()
          ..addAll((decoded['childAgeFilter'] as List?)
                  ?.map((e) => e.toString())
                  .toSet() ??
              <String>{});

        _myInterests
          ..clear()
          ..addAll((decoded['myInterests'] as List?)
                  ?.map((e) => e.toString())
                  .toSet() ??
              _defaultMyInterests);
        _myLanguages
          ..clear()
          ..addAll((decoded['myLanguages'] as List?)
                  ?.map((e) => e.toString())
                  .toSet() ??
              _defaultMyLanguages);
        _myValues
          ..clear()
          ..addAll((decoded['myValues'] as List?)
                  ?.map((e) => e.toString())
                  .toSet() ??
              _defaultMyValues);
        _homeCity = (decoded['homeCity'] ?? _homeCity).toString();
        _maxDistanceKm =
            (decoded['maxDistanceKm'] as num?)?.toDouble().clamp(3, 100) ?? 20;

        _currentIndex = (decoded['currentIndex'] as num?)?.toInt() ?? 0;
        _isRestoring = false;
      });
    } catch (e) {
      debugPrint('ParentMatchingScreen._restoreState(): failed: $e');
      if (!mounted) return;
      setState(() => _isRestoring = false);
    }
  }

  Future<void> _persistState() async {
    final prefs = await SharedPreferences.getInstance();
    final payload = {
      'likedIds': _likedProfiles.map((p) => p.id).toList(),
      'matchedIds': _matchedProfiles.map((p) => p.id).toList(),
      'blockedIds': _blockedProfileIds.toList(),
      'reportedIds': _reportedProfileIds.toList(),
      'interestFilter': _interestFilter.toList(),
      'languageFilter': _languageFilter.toList(),
      'valuesFilter': _valuesFilter.toList(),
      'familyFormFilter': _familyFormFilter.toList(),
      'childAgeFilter': _childAgeFilter.toList(),
      'myInterests': _myInterests.toList(),
      'myLanguages': _myLanguages.toList(),
      'myValues': _myValues.toList(),
      'homeCity': _homeCity,
      'maxDistanceKm': _maxDistanceKm,
      'seenMatchedProfileIds': _seenMatchedProfileIds.toList(),
      'currentIndex': _currentIndex,
    };
    await prefs.setString(_storageKey, jsonEncode(payload));
  }

  Future<void> _refreshConnectionsFromBackend({bool announce = true}) async {
    try {
      // Fetch latest matches using smart algorithm
      final matchResults = await _service.findMatches(userId: _effectiveUserId);

      // Get connected profile IDs from backend
      final connectedIds =
          await _service.fetchConnectedProfileIds(userId: _effectiveUserId);
      final newlyConfirmedIds = connectedIds.difference(_seenMatchedProfileIds);

      if (!mounted) return;

      // Update both all profiles and matched profiles
      final profiles = matchResults.map((result) {
        final profile = result.profile;
        // Convert breakdown map values to doubles
        final breakdownAsDoubles = result.breakdown.map(
          (key, value) =>
              MapEntry(key, (value is num) ? value.toDouble() : 0.0),
        );
        final age = profile.age;
        final familyForm = profile.familyForm;
        return _ParentProfile(
          id: profile.id,
          name: profile.name ?? 'Unbekannt',
          age: (age != null) ? age : 30,
          city: profile.city,
          bio: 'Matching-Score: ${result.score.toStringAsFixed(0)}%',
          interests: profile.interests,
          languages: profile.languages,
          valuesFocus: profile.valuesFocus,
          familyForm: (familyForm != null) ? familyForm : 'Familie',
          childAges: profile.childAges,
          latitude: profile.latitude,
          longitude: profile.longitude,
          score: result.score as double?,
          breakdown: breakdownAsDoubles,
        );
      }).toList();

      setState(() {
        _allProfiles
          ..clear()
          ..addAll(profiles);

        _matchedProfiles
          ..clear()
          ..addAll(_allProfiles.where((p) => connectedIds.contains(p.id)));
        _newlyConfirmedProfileIds
          ..clear()
          ..addAll(newlyConfirmedIds);
        _newConfirmedSinceLastVisit = _newlyConfirmedProfileIds.length;
      });

      if (announce && newlyConfirmedIds.isNotEmpty) {
        final count = newlyConfirmedIds.length;
        final text = count == 1
            ? 'Neue bestätigte Verbindung verfügbar.'
            : '$count neue bestätigte Verbindungen verfügbar.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(text),
            duration: const Duration(seconds: 3),
          ),
        );
      }

      _persistState();
    } catch (e) {
      // Fallback - try the old method
      final connectedIds =
          await _service.fetchConnectedProfileIds(userId: _effectiveUserId);
      final newlyConfirmedIds = connectedIds.difference(_seenMatchedProfileIds);

      if (!mounted) return;
      setState(() {
        _matchedProfiles
          ..clear()
          ..addAll(_allProfiles.where((p) => connectedIds.contains(p.id)));
        _newlyConfirmedProfileIds
          ..clear()
          ..addAll(newlyConfirmedIds);
        _newConfirmedSinceLastVisit = _newlyConfirmedProfileIds.length;
      });

      if (announce && newlyConfirmedIds.isNotEmpty) {
        final count = newlyConfirmedIds.length;
        final text = count == 1
            ? 'Neue bestätigte Verbindung verfügbar.'
            : '$count neue bestätigte Verbindungen verfügbar.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(text),
            duration: const Duration(seconds: 3),
          ),
        );
      }

      _persistState();
    }
  }

  Future<void> _acknowledgeNewConnections() async {
    setState(() {
      _seenMatchedProfileIds.addAll(_matchedProfiles.map((p) => p.id));
      _newlyConfirmedProfileIds.clear();
      _newConfirmedSinceLastVisit = 0;
    });
    await _persistState();
  }

  void _openNewConnectionsSheet() {
    final names = _matchedProfiles
        .where((profile) => _newlyConfirmedProfileIds.contains(profile.id))
        .map((profile) => profile.name)
        .toList();

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Neue bestätigte Verbindungen',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                if (names.isEmpty)
                  const Text('Aktuell keine neuen bestätigten Verbindungen.')
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: names
                        .map(
                          (name) => Chip(
                            avatar:
                                const Icon(Icons.handshake_rounded, size: 16),
                            label: Text(name),
                          ),
                        )
                        .toList(),
                  ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () async {
                      await _acknowledgeNewConnections();
                      if (!context.mounted) return;
                      Navigator.pop(context);
                    },
                    child: const Text('Alles gesehen'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<_ParentProfile> get _filteredProfiles {
    final list = _allProfiles.where((profile) {
      if (_blockedProfileIds.contains(profile.id)) {
        return false;
      }
      if (_reportedProfileIds.contains(profile.id)) {
        return false;
      }
      if (_interestFilter.isNotEmpty &&
          profile.interests.toSet().intersection(_interestFilter).isEmpty) {
        return false;
      }
      if (_languageFilter.isNotEmpty &&
          profile.languages.toSet().intersection(_languageFilter).isEmpty) {
        return false;
      }
      if (_valuesFilter.isNotEmpty &&
          profile.valuesFocus.toSet().intersection(_valuesFilter).isEmpty) {
        return false;
      }
      if (_familyFormFilter.isNotEmpty &&
          !_familyFormFilter.contains(profile.familyForm)) {
        return false;
      }
      if (_childAgeFilter.isNotEmpty &&
          profile.childAges.toSet().intersection(_childAgeFilter).isEmpty) {
        return false;
      }
      final distanceKm = _distanceKm(profile);
      if (distanceKm != null && distanceKm > _maxDistanceKm) {
        return false;
      }
      return true;
    }).toList();

    list.sort((a, b) => _compatibility(b).compareTo(_compatibility(a)));
    return list;
  }

  _ParentProfile? get _currentProfile {
    final list = _filteredProfiles;
    if (list.isEmpty || _currentIndex >= list.length) return null;
    return list[_currentIndex];
  }

  List<_ParentProfile> get _pendingProfiles {
    final matchedIds = _matchedProfiles.map((p) => p.id).toSet();
    return _likedProfiles.where((p) => !matchedIds.contains(p.id)).toList();
  }

  void _moveNext() {
    final list = _filteredProfiles;
    if (list.isEmpty) return;
    setState(() {
      if (_currentIndex < list.length - 1) {
        _currentIndex += 1;
      } else {
        _currentIndex = 0;
      }
    });
    _persistState();
  }

  int _compatibility(_ParentProfile profile) {
    final interestsMatch =
        profile.interests.toSet().intersection(_myInterests).length;
    final languagesMatch =
        profile.languages.toSet().intersection(_myLanguages).length;
    final valuesMatch =
        profile.valuesFocus.toSet().intersection(_myValues).length;
    final distanceKm = _distanceKm(profile);

    var distanceBoost = 0;
    if (distanceKm != null) {
      if (distanceKm <= 5) {
        distanceBoost = 18;
      } else if (distanceKm <= 10) {
        distanceBoost = 12;
      } else if (distanceKm <= 20) {
        distanceBoost = 8;
      } else if (distanceKm <= _maxDistanceKm) {
        distanceBoost = 4;
      }
    }

    final base = (interestsMatch * 15) +
        (languagesMatch * 13) +
        (valuesMatch * 11) +
        distanceBoost;
    return min(98, max(45, base));
  }

  (double, double)? get _homeLatLng => _cityCenters[_homeCity];

  double? _distanceKm(_ParentProfile profile) {
    if (profile.latitude == null || profile.longitude == null) {
      return null;
    }
    final home = _homeLatLng;
    if (home == null) return null;
    return _haversineKm(
        home.$1, home.$2, profile.latitude!, profile.longitude!);
  }

  double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
    const earthRadiusKm = 6371.0;
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = pow(sin(dLat / 2), 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) * pow(sin(dLon / 2), 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }

  double _toRadians(double degree) => degree * pi / 180;

  int _categoryScore(List<String> profileValues, Set<String> myValues) {
    if (profileValues.isEmpty) return 0;
    final overlap = profileValues.toSet().intersection(myValues).length;
    return min(100, ((overlap / profileValues.length) * 100).round());
  }

  _MatchQuality _matchQuality(_ParentProfile profile) {
    return _MatchQuality(
      interests: _categoryScore(profile.interests, _myInterests),
      languages: _categoryScore(profile.languages, _myLanguages),
      values: _categoryScore(profile.valuesFocus, _myValues),
    );
  }

  List<String> _whyMatch(_ParentProfile profile) {
    final reasons = <String>[];
    final sharedInterests =
        profile.interests.toSet().intersection(_myInterests).toList();
    final sharedLanguages =
        profile.languages.toSet().intersection(_myLanguages).toList();
    final sharedValues =
        profile.valuesFocus.toSet().intersection(_myValues).toList();

    if (sharedInterests.isNotEmpty) {
      reasons
          .add('Gemeinsame Interessen: ${sharedInterests.take(2).join(', ')}');
    }
    if (sharedLanguages.isNotEmpty) {
      reasons.add('Sprache passt: ${sharedLanguages.take(2).join(', ')}');
    }
    if (sharedValues.isNotEmpty) {
      reasons.add('Ähnliche Werte: ${sharedValues.take(2).join(', ')}');
    }
    final distance = _distanceKm(profile);
    if (distance != null) {
      reasons.add('Wohnortnähe: ${distance.toStringAsFixed(1)} km entfernt');
    }
    if (reasons.isEmpty) {
      reasons.add('Passende Familienphase und Offenheit für Austausch');
    }
    return reasons;
  }

  Future<void> _likeCurrent() async {
    final profile = _currentProfile;
    if (profile == null) return;

    if (!_likedProfiles.any((p) => p.id == profile.id)) {
      _likedProfiles.add(profile);
    }

    final score = _compatibility(profile);

    _moveNext();
    _persistState();
    final result = await _service.sendAction(
      profileId: profile.id,
      action: 'like',
      userId: _effectiveUserId,
    );
    await _refreshConnectionsFromBackend(announce: false);
    if (!mounted) return;

    if (result.connected || result.matchState == 'matched') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Match bestätigt mit ${profile.name} ($score%)'),
          duration: const Duration(seconds: 2),
        ),
      );
    } else if (result.matchState == 'pending') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Anfrage an ${profile.name} gesendet. Wir melden uns, sobald es gegenseitig ist.'),
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Anfrage gesendet. Verbindung wird bestätigt.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _reportCurrent() {
    final profile = _currentProfile;
    if (profile == null) return;

    setState(() {
      _reportedProfileIds.add(profile.id);
      _likedProfiles.removeWhere((p) => p.id == profile.id);
      _matchedProfiles.removeWhere((p) => p.id == profile.id);
      _currentIndex = 0;
    });
    _persistState();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text('Profil ${profile.name} wurde gemeldet und ausgeblendet.'),
        duration: const Duration(seconds: 2),
      ),
    );

    _service.sendAction(
      profileId: profile.id,
      action: 'report',
      userId: _effectiveUserId,
    );
  }

  void _blockCurrent() {
    final profile = _currentProfile;
    if (profile == null) return;

    setState(() {
      _blockedProfileIds.add(profile.id);
      _likedProfiles.removeWhere((p) => p.id == profile.id);
      _matchedProfiles.removeWhere((p) => p.id == profile.id);
      _currentIndex = 0;
    });
    _persistState();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${profile.name} wurde blockiert.'),
        duration: const Duration(seconds: 2),
      ),
    );

    _service.sendAction(
      profileId: profile.id,
      action: 'block',
      userId: _effectiveUserId,
    );
  }

  Future<void> _saveMyProfile() async {
    final name = _profileNameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte gib einen Namen ein.')),
      );
      return;
    }

    setState(() => _isSavingProfile = true);

    // Get city coordinates
    final cityCenter = _cityCenters[_homeCity] ?? _cityCenters['Berlin']!;

    final saved = await _service.createProfile(
      userId: _effectiveUserId,
      name: name,
      age: _profileAge,
      city: _homeCity,
      latitude: cityCenter.$1,
      longitude: cityCenter.$2,
      interests: _myInterests.toList(),
      languages: _myLanguages.toList(),
      valuesFocus: _myValues.toList(),
      childAges: _childAgeFilter.isNotEmpty
          ? _childAgeFilter.toList()
          : const ['3-5', '6-9'],
      familyForm: _profileFamilyForm,
    );
    if (!mounted) return;

    if (saved == null) {
      setState(() => _isSavingProfile = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _service.lastSyncError ??
                'Matching-Profil konnte nicht gespeichert werden.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isSavingProfile = false;
      _requiresProfileSetup = false;
      _isRestoring = true;
    });
    await _bootstrap();
  }

  Widget _buildProfileSetupRequired() {
    return Scaffold(
      appBar: AppBar(title: const Text('Eltern-Matching einrichten')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Text(
              'Bitte richte zuerst dein Eltern-Matching-Profil ein, damit andere Familien dich finden können.',
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _profileNameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _homeCity,
                    decoration: const InputDecoration(
                      labelText: 'Stadt',
                      border: OutlineInputBorder(),
                    ),
                    items: _cityCenters.keys
                        .map((city) => DropdownMenuItem<String>(
                              value: city,
                              child: Text(city),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _homeCity = value);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: _profileAge,
                    decoration: const InputDecoration(
                      labelText: 'Alter',
                      border: OutlineInputBorder(),
                    ),
                    items: List.generate(54, (i) => i + 18)
                        .map((age) => DropdownMenuItem<int>(
                              value: age,
                              child: Text('$age'),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _profileAge = value);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _profileFamilyForm,
              decoration: const InputDecoration(
                labelText: 'Familienform',
                border: OutlineInputBorder(),
              ),
              items: const [
                'Alleinerziehend',
                'Patchwork',
                'Kernfamilie',
                'Mehrgeneration',
              ]
                  .map((form) => DropdownMenuItem<String>(
                        value: form,
                        child: Text(form),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() => _profileFamilyForm = value);
              },
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _isSavingProfile ? null : _saveMyProfile,
              icon: _isSavingProfile
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_rounded),
              label:
                  Text(_isSavingProfile ? 'Speichern...' : 'Profil speichern'),
            ),
          ],
        ),
      ),
    );
  }

  void _openSafetyInfo() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            children: [
              Text(
                'Sicherheit im Eltern-Matching',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const ListTile(
                leading: Icon(Icons.flag_outlined),
                title: Text('Profile melden'),
                subtitle: Text(
                    'Unpassende Inhalte können jederzeit gemeldet werden.'),
              ),
              const ListTile(
                leading: Icon(Icons.block_rounded),
                title: Text('Profile blockieren'),
                subtitle:
                    Text('Blockierte Profile werden nicht mehr angezeigt.'),
              ),
              ListTile(
                leading: const Icon(Icons.verified_user_outlined),
                title: const Text('Aktueller Status'),
                subtitle: Text(
                    '${_matchedProfiles.length} Verbindungen, ${_blockedProfileIds.length} blockierte Profile, ${_reportedProfileIds.length} gemeldete Profile'),
              ),
              if (_reportedProfileIds.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.inventory_2_outlined),
                  title: const Text('Safety-Queue'),
                  subtitle: Text(
                      '${_reportedProfileIds.length} Profile in Prüfung (lokal markiert)'),
                ),
            ],
          ),
        );
      },
    );
  }

  void _openMatchChat(_ParentProfile profile) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MatchConversationScreen(
          profileId: profile.id,
          profileName: profile.name,
        ),
      ),
    );
  }

  void _skipCurrent() {
    _moveNext();
  }

  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Widget buildFilterGroup({
              required String title,
              required List<String> options,
              required Set<String> selected,
            }) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: options.map((option) {
                      final isSelected = selected.contains(option);
                      return FilterChip(
                        label: Text(option),
                        selected: isSelected,
                        onSelected: (value) {
                          setModalState(() {
                            if (value) {
                              selected.add(option);
                            } else {
                              selected.remove(option);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              );
            }

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('Matching-Filter',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 18)),
                          const Spacer(),
                          TextButton(
                            onPressed: () {
                              setModalState(() {
                                _interestFilter.clear();
                                _languageFilter.clear();
                                _valuesFilter.clear();
                                _familyFormFilter.clear();
                                _childAgeFilter.clear();
                              });
                            },
                            child: const Text('Reset'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      buildFilterGroup(
                        title: 'Interessen',
                        options: const [
                          'Bildung',
                          'Outdoor',
                          'Sport',
                          'Familienzeit',
                          'Kreativ',
                          'Gesundheit',
                          'Spielplatz'
                        ],
                        selected: _interestFilter,
                      ),
                      const SizedBox(height: 14),
                      buildFilterGroup(
                        title: 'Sprache',
                        options: const [
                          'Deutsch',
                          'Englisch',
                          'Türkisch',
                          'Arabisch',
                          'Kurdisch',
                          'Französisch'
                        ],
                        selected: _languageFilter,
                      ),
                      const SizedBox(height: 14),
                      buildFilterGroup(
                        title: 'Weltanschauung und Werte',
                        options: const [
                          'Gewaltfrei',
                          'Respekt',
                          'Inklusion',
                          'Empathie',
                          'Tradition',
                          'Offenheit'
                        ],
                        selected: _valuesFilter,
                      ),
                      const SizedBox(height: 14),
                      buildFilterGroup(
                        title: 'Familienform',
                        options: const [
                          'Alleinerziehend',
                          'Patchwork',
                          'Kernfamilie',
                          'Mehrgeneration'
                        ],
                        selected: _familyFormFilter,
                      ),
                      const SizedBox(height: 14),
                      buildFilterGroup(
                        title: 'Kinderalter',
                        options: const ['0-2', '3-5', '6-9', '10-13', '14+'],
                        selected: _childAgeFilter,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () {
                            setState(() {
                              _currentIndex = 0;
                            });
                            _persistState();
                            Navigator.pop(context);
                          },
                          child: const Text('Filter anwenden'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openPreferenceSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Widget buildGroup({
              required String title,
              required List<String> options,
              required Set<String> selected,
            }) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: options.map((option) {
                      final isSelected = selected.contains(option);
                      return FilterChip(
                        label: Text(option),
                        selected: isSelected,
                        onSelected: (value) {
                          setModalState(() {
                            if (value) {
                              selected.add(option);
                            } else {
                              selected.remove(option);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              );
            }

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('Mein Matching-Profil',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 18)),
                          const Spacer(),
                          TextButton(
                            onPressed: () {
                              setModalState(() {
                                _myInterests
                                  ..clear()
                                  ..addAll(_defaultMyInterests);
                                _myLanguages
                                  ..clear()
                                  ..addAll(_defaultMyLanguages);
                                _myValues
                                  ..clear()
                                  ..addAll(_defaultMyValues);
                                _homeCity = 'Berlin';
                                _maxDistanceKm = 20;
                              });
                            },
                            child: const Text('Reset'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _homeCity,
                        decoration: const InputDecoration(
                          labelText: 'Standort (Mittelpunkt)',
                          border: OutlineInputBorder(),
                        ),
                        items: _cityCenters.keys
                            .map((city) => DropdownMenuItem<String>(
                                  value: city,
                                  child: Text(city),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setModalState(() => _homeCity = value);
                        },
                      ),
                      const SizedBox(height: 12),
                      Text('Radius: ${_maxDistanceKm.toStringAsFixed(0)} km'),
                      Slider(
                        value: _maxDistanceKm,
                        min: 3,
                        max: 100,
                        divisions: 97,
                        label: '${_maxDistanceKm.toStringAsFixed(0)} km',
                        onChanged: (value) {
                          setModalState(() => _maxDistanceKm = value);
                        },
                      ),
                      const SizedBox(height: 8),
                      buildGroup(
                        title: 'Meine Interessen',
                        options: const [
                          'Bildung',
                          'Outdoor',
                          'Sport',
                          'Familienzeit',
                          'Kreativ',
                          'Gesundheit',
                          'Spielplatz'
                        ],
                        selected: _myInterests,
                      ),
                      const SizedBox(height: 14),
                      buildGroup(
                        title: 'Meine Sprachen',
                        options: const [
                          'Deutsch',
                          'Englisch',
                          'Türkisch',
                          'Arabisch',
                          'Kurdisch',
                          'Französisch'
                        ],
                        selected: _myLanguages,
                      ),
                      const SizedBox(height: 14),
                      buildGroup(
                        title: 'Meine Werte',
                        options: const [
                          'Gewaltfrei',
                          'Respekt',
                          'Inklusion',
                          'Empathie',
                          'Tradition',
                          'Offenheit'
                        ],
                        selected: _myValues,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () {
                            setState(() {
                              _currentIndex = 0;
                            });
                            _persistState();
                            Navigator.pop(context);
                          },
                          child: const Text('Speichern'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = _currentProfile;

    if (_requiresProfileSetup) {
      return _buildProfileSetupRequired();
    }

    if (_isRestoring) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Eltern-Matching'),
        actions: [
          IconButton(
            tooltip: 'Neue Verbindungen',
            onPressed: _openNewConnectionsSheet,
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_none_rounded),
                if (_newConfirmedSinceLastVisit > 0)
                  Positioned(
                    right: -6,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDC2626),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _newConfirmedSinceLastVisit > 9
                            ? '9+'
                            : _newConfirmedSinceLastVisit.toString(),
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
          IconButton(
            tooltip: 'Mein Profil',
            onPressed: _openPreferenceSheet,
            icon: const Icon(Icons.tune_rounded),
          ),
          IconButton(
            tooltip: 'Sicherheit',
            onPressed: _openSafetyInfo,
            icon: const Icon(Icons.shield_outlined),
          ),
          IconButton(
            tooltip: 'Suche filtern',
            onPressed: _openFilterSheet,
            icon: const Icon(Icons.filter_list_rounded),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                _StatPill(
                  icon: Icons.group_add_rounded,
                  label: 'Interesse',
                  value: _likedProfiles.length,
                  color: const Color(0xFF0EA5A4),
                ),
                const SizedBox(width: 8),
                _StatPill(
                  icon: Icons.hourglass_top_rounded,
                  label: 'Ausstehend',
                  value: _pendingProfiles.length,
                  color: const Color(0xFFF59E0B),
                ),
                const SizedBox(width: 8),
                _StatPill(
                  icon: Icons.handshake_rounded,
                  label: 'Verbindungen',
                  value: _matchedProfiles.length,
                  color: const Color(0xFF2563EB),
                ),
                const Spacer(),
                Text(
                  '${_filteredProfiles.isEmpty ? 0 : (_currentIndex + 1)}/${_filteredProfiles.length}',
                  style: theme.textTheme.labelLarge,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer
                    .withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Nur für Freundschaft, Playdates und Eltern-Austausch · Radius ${_maxDistanceKm.toStringAsFixed(0)} km ab $_homeCity',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: profile == null
                  ? _EmptyMatchState(onReset: () {
                      setState(() {
                        _currentIndex = 0;
                        _interestFilter.clear();
                        _languageFilter.clear();
                        _valuesFilter.clear();
                        _familyFormFilter.clear();
                        _childAgeFilter.clear();
                      });
                      _persistState();
                    })
                  : Column(
                      children: [
                        Expanded(
                          child: _ProfileCard(
                            profile: profile,
                            compatibility: _compatibility(profile),
                            distanceKm: _distanceKm(profile),
                            quality: _matchQuality(profile),
                            reasons: _whyMatch(profile),
                            onReport: _reportCurrent,
                            onBlock: _blockCurrent,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _skipCurrent,
                                icon: const Icon(Icons.close_rounded),
                                label: const Text('Weiter'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: _likeCurrent,
                                icon: const Icon(Icons.handshake_rounded),
                                label: const Text('Verbinden'),
                              ),
                            ),
                          ],
                        ),
                        if (_pendingProfiles.isNotEmpty ||
                            _matchedProfiles.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 120),
                            child: SingleChildScrollView(
                              child: Column(
                                children: [
                                  if (_pendingProfiles.isNotEmpty)
                                    Container(
                                      width: double.infinity,
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: theme
                                            .colorScheme.tertiaryContainer
                                            .withValues(alpha: 0.5),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Ausstehende Anfragen',
                                            style: theme.textTheme.labelLarge
                                                ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 8,
                                            children: _pendingProfiles
                                                .map((p) => Chip(
                                                      avatar: const Icon(
                                                        Icons
                                                            .hourglass_top_rounded,
                                                        size: 16,
                                                      ),
                                                      label: Text(p.name),
                                                    ))
                                                .toList(),
                                          ),
                                        ],
                                      ),
                                    ),
                                  if (_matchedProfiles.isNotEmpty)
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: theme
                                            .colorScheme.primaryContainer
                                            .withValues(alpha: 0.5),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: _matchedProfiles
                                            .map((p) => Chip(
                                                  avatar: CircleAvatar(
                                                    child: Text(
                                                        _safeInitial(p.name)),
                                                  ),
                                                  label: Text(p.name),
                                                  onDeleted: () =>
                                                      _openMatchChat(p),
                                                  deleteIcon: const Icon(Icons
                                                      .chat_bubble_outline_rounded),
                                                ))
                                            .toList(),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text('$label: $value',
              style: TextStyle(color: color, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.profile,
    required this.compatibility,
    required this.distanceKm,
    required this.quality,
    required this.reasons,
    required this.onReport,
    required this.onBlock,
  });

  final _ParentProfile profile;
  final int compatibility;
  final double? distanceKm;
  final _MatchQuality quality;
  final List<String> reasons;
  final VoidCallback onReport;
  final VoidCallback onBlock;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF06B6D4), Color(0xFF8B5CF6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white.withValues(alpha: 0.25),
                  child: Text(_safeInitial(profile.name),
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 22)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text('${profile.name}, ${profile.age}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700)),
                          ),
                          _VerificationBadge(level: profile.verificationLevel),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                          distanceKm == null
                              ? profile.city
                              : '${profile.city} · ${distanceKm!.toStringAsFixed(1)} km',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.95),
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text('$compatibility%',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w700)),
                ),
                PopupMenuButton<String>(
                  color: Colors.white,
                  iconColor: Colors.white,
                  onSelected: (value) {
                    if (value == 'report') onReport();
                    if (value == 'block') onBlock();
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem<String>(
                      value: 'report',
                      child: Text('Profil melden'),
                    ),
                    PopupMenuItem<String>(
                      value: 'block',
                      child: Text('Profil blockieren'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(profile.bio,
                    style: theme.textTheme.bodyLarge?.copyWith(height: 1.35)),
                const SizedBox(height: 14),
                _TagSection(title: 'Interessen', values: profile.interests),
                const SizedBox(height: 10),
                _TagSection(title: 'Sprachen', values: profile.languages),
                const SizedBox(height: 10),
                _TagSection(title: 'Werte', values: profile.valuesFocus),
                const SizedBox(height: 10),
                _TagSection(title: 'Kinderalter', values: profile.childAges),
                const SizedBox(height: 10),
                _MatchQualityRow(quality: quality),
                const SizedBox(height: 10),
                _TagSection(title: 'Warum ihr passt', values: reasons),
                const SizedBox(height: 10),
                Text('Familienform: ${profile.familyForm}',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TagSection extends StatelessWidget {
  const _TagSection({required this.title, required this.values});

  final String title;
  final List<String> values;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: values
              .map((v) => Chip(
                    visualDensity: VisualDensity.compact,
                    label: Text(v),
                  ))
              .toList(),
        ),
      ],
    );
  }
}

class _MatchQuality {
  const _MatchQuality({
    required this.interests,
    required this.languages,
    required this.values,
  });

  final int interests;
  final int languages;
  final int values;
}

class _MatchQualityRow extends StatelessWidget {
  const _MatchQualityRow({required this.quality});

  final _MatchQuality quality;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Match-Qualität',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _QualityPill(label: 'Interessen', score: quality.interests),
            _QualityPill(label: 'Sprache', score: quality.languages),
            _QualityPill(label: 'Werte', score: quality.values),
          ],
        ),
      ],
    );
  }
}

class _QualityPill extends StatelessWidget {
  const _QualityPill({required this.label, required this.score});

  final String label;
  final int score;

  @override
  Widget build(BuildContext context) {
    final Color color;
    if (score >= 80) {
      color = const Color(0xFF16A34A);
    } else if (score >= 55) {
      color = const Color(0xFF0EA5E9);
    } else {
      color = const Color(0xFFF59E0B);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        '$label $score%',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _EmptyMatchState extends StatelessWidget {
  const _EmptyMatchState({required this.onReset});

  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off_rounded, size: 56),
          const SizedBox(height: 10),
          const Text('Keine Profile für die aktuellen Filter.'),
          const SizedBox(height: 10),
          OutlinedButton(onPressed: onReset, child: const Text('Filter reset')),
        ],
      ),
    );
  }
}

class _ParentProfile {
  const _ParentProfile({
    required this.id,
    required this.name,
    required this.age,
    required this.city,
    required this.bio,
    required this.interests,
    required this.languages,
    required this.valuesFocus,
    required this.childAges,
    required this.familyForm,
    this.latitude,
    this.longitude,
    this.verificationLevel = _VerificationLevel.basic,
    this.score,
    this.breakdown,
  });

  final String id;
  final String name;
  final int age;
  final String city;
  final String bio;
  final List<String> interests;
  final List<String> languages;
  final List<String> valuesFocus;
  final List<String> childAges;
  final String familyForm;
  final double? latitude;
  final double? longitude;
  final _VerificationLevel verificationLevel;
  final double? score;
  final Map<String, double>? breakdown;
}

String _safeInitial(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) {
    return '?';
  }
  return trimmed.substring(0, 1).toUpperCase();
}

enum _VerificationLevel { basic, checked, recommended }

class _VerificationBadge extends StatelessWidget {
  const _VerificationBadge({required this.level});

  final _VerificationLevel level;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (level) {
      _VerificationLevel.basic => ('Basis', Colors.white70),
      _VerificationLevel.checked => ('Geprüft', const Color(0xFF93C5FD)),
      _VerificationLevel.recommended => ('Empfohlen', const Color(0xFFFDE68A)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.8)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_rounded, color: color, size: 15),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w700, fontSize: 11)),
        ],
      ),
    );
  }
}
