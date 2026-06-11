import 'dart:math';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trusted_circle_demo/ui/match_conversation_screen.dart';

class ParentMatchingScreen extends StatefulWidget {
  const ParentMatchingScreen({super.key});

  @override
  State<ParentMatchingScreen> createState() => _ParentMatchingScreenState();
}

class _ParentMatchingScreenState extends State<ParentMatchingScreen> {
  static const String _storageKey = 'parent_matching.v1';

  final List<_ParentProfile> _allProfiles = _seedProfiles();
  final List<_ParentProfile> _likedProfiles = [];
  final List<_ParentProfile> _matchedProfiles = [];
  final Set<String> _blockedProfileIds = {};
  final Set<String> _reportedProfileIds = {};

  final Set<String> _interestFilter = {};
  final Set<String> _languageFilter = {};
  final Set<String> _valuesFilter = {};
  final Set<String> _familyFormFilter = {};
  final Set<String> _childAgeFilter = {};

  int _currentIndex = 0;
  bool _isRestoring = true;

  @override
  void initState() {
    super.initState();
    _restoreState();
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

        _currentIndex = (decoded['currentIndex'] as num?)?.toInt() ?? 0;
        _isRestoring = false;
      });
    } catch (_) {
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
      'currentIndex': _currentIndex,
    };
    await prefs.setString(_storageKey, jsonEncode(payload));
  }

  List<_ParentProfile> get _filteredProfiles {
    return _allProfiles.where((profile) {
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
      return true;
    }).toList();
  }

  _ParentProfile? get _currentProfile {
    final list = _filteredProfiles;
    if (list.isEmpty || _currentIndex >= list.length) return null;
    return list[_currentIndex];
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
    const myInterests = {
      'Bildung',
      'Spielplatz',
      'Familienzeit',
      'Outdoor',
      'Gesundheit'
    };
    const myLanguages = {'Deutsch', 'Englisch'};
    const myValues = {'Gewaltfrei', 'Respekt', 'Inklusion', 'Empathie'};

    final interestsMatch =
        profile.interests.toSet().intersection(myInterests).length;
    final languagesMatch =
        profile.languages.toSet().intersection(myLanguages).length;
    final valuesMatch = profile.valuesFocus.toSet().intersection(myValues).length;

    final base = (interestsMatch * 18) + (languagesMatch * 16) + (valuesMatch * 14);
    return min(98, max(45, base));
  }

  List<String> _whyMatch(_ParentProfile profile) {
    const myInterests = {
      'Bildung',
      'Spielplatz',
      'Familienzeit',
      'Outdoor',
      'Gesundheit'
    };
    const myLanguages = {'Deutsch', 'Englisch'};
    const myValues = {'Gewaltfrei', 'Respekt', 'Inklusion', 'Empathie'};

    final reasons = <String>[];
    final sharedInterests =
        profile.interests.toSet().intersection(myInterests).toList();
    final sharedLanguages =
        profile.languages.toSet().intersection(myLanguages).toList();
    final sharedValues = profile.valuesFocus.toSet().intersection(myValues).toList();

    if (sharedInterests.isNotEmpty) {
      reasons.add('Gemeinsame Interessen: ${sharedInterests.take(2).join(', ')}');
    }
    if (sharedLanguages.isNotEmpty) {
      reasons.add('Sprache passt: ${sharedLanguages.take(2).join(', ')}');
    }
    if (sharedValues.isNotEmpty) {
      reasons.add('Aehnliche Werte: ${sharedValues.take(2).join(', ')}');
    }
    if (reasons.isEmpty) {
      reasons.add('Passende Familienphase und Offenheit fuer Austausch');
    }
    return reasons;
  }

  void _likeCurrent() {
    final profile = _currentProfile;
    if (profile == null) return;

    if (!_likedProfiles.any((p) => p.id == profile.id)) {
      _likedProfiles.add(profile);
    }

    final score = _compatibility(profile);
    final isMatch = score >= 70;
    if (isMatch && !_matchedProfiles.any((p) => p.id == profile.id)) {
      _matchedProfiles.add(profile);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Neuer Match mit ${profile.name} ($score%)'),
          duration: const Duration(seconds: 2),
        ),
      );
    }

    _moveNext();
    _persistState();
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
        content: Text('Profil ${profile.name} wurde gemeldet und ausgeblendet.'),
        duration: const Duration(seconds: 2),
      ),
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
                subtitle: Text('Unpassende Inhalte koennen jederzeit gemeldet werden.'),
              ),
              const ListTile(
                leading: Icon(Icons.block_rounded),
                title: Text('Profile blockieren'),
                subtitle: Text('Blockierte Profile werden nicht mehr angezeigt.'),
              ),
              ListTile(
                leading: const Icon(Icons.verified_user_outlined),
                title: const Text('Aktueller Status'),
                subtitle: Text(
                    '${_matchedProfiles.length} Matches, ${_blockedProfileIds.length} blockierte Profile, ${_reportedProfileIds.length} gemeldete Profile'),
              ),
              if (_reportedProfileIds.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.inventory_2_outlined),
                  title: const Text('Safety-Queue'),
                  subtitle: Text(
                      '${_reportedProfileIds.length} Profile in Pruefung (lokal markiert)'),
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
        builder: (_) => MatchConversationScreen(profileName: profile.name),
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
                          'Tuerkisch',
                          'Arabisch',
                          'Kurdisch',
                          'Franzoesisch'
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
                        options: const [
                          '0-2',
                          '3-5',
                          '6-9',
                          '10-13',
                          '14+'
                        ],
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = _currentProfile;

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
            tooltip: 'Sicherheit',
            onPressed: _openSafetyInfo,
            icon: const Icon(Icons.shield_outlined),
          ),
          IconButton(
            tooltip: 'Filter',
            onPressed: _openFilterSheet,
            icon: const Icon(Icons.tune_rounded),
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
                  icon: Icons.favorite_border,
                  label: 'Likes',
                  value: _likedProfiles.length,
                  color: const Color(0xFFEC4899),
                ),
                const SizedBox(width: 8),
                _StatPill(
                  icon: Icons.bolt_rounded,
                  label: 'Matches',
                  value: _matchedProfiles.length,
                  color: const Color(0xFF7C3AED),
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
                color: theme.colorScheme.secondaryContainer.withOpacity(0.45),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Nur fuer Freundschaft, Playdates und Eltern-Austausch.',
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
                  : _ProfileCard(
                      profile: profile,
                      compatibility: _compatibility(profile),
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
                    onPressed: profile == null ? null : _skipCurrent,
                    icon: const Icon(Icons.close_rounded),
                    label: const Text('Weiter'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: profile == null ? null : _likeCurrent,
                    icon: const Icon(Icons.favorite_rounded),
                    label: const Text('Matchen'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (_matchedProfiles.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _matchedProfiles
                      .map((p) => Chip(
                            avatar: CircleAvatar(
                              child: Text(p.name[0]),
                            ),
                            label: Text(p.name),
                            onDeleted: () => _openMatchChat(p),
                            deleteIcon: const Icon(Icons.chat_bubble_outline_rounded),
                          ))
                      .toList(),
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
        color: color.withOpacity(0.12),
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
    required this.reasons,
    required this.onReport,
    required this.onBlock,
  });

  final _ParentProfile profile;
  final int compatibility;
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
                  backgroundColor: Colors.white.withOpacity(0.25),
                  child: Text(profile.name[0],
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
                      Text(profile.city,
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.95),
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
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
            style:
                const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
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
          const Text('Keine Profile fuer die aktuellen Filter.'),
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
    this.verificationLevel = _VerificationLevel.basic,
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
  final _VerificationLevel verificationLevel;
}

enum _VerificationLevel { basic, checked, recommended }

class _VerificationBadge extends StatelessWidget {
  const _VerificationBadge({required this.level});

  final _VerificationLevel level;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (level) {
      _VerificationLevel.basic => ('Basis', Colors.white70),
      _VerificationLevel.checked => ('Geprueft', Color(0xFF93C5FD)),
      _VerificationLevel.recommended => ('Empfohlen', Color(0xFFFDE68A)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.8)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_rounded, color: color, size: 15),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 11)),
        ],
      ),
    );
  }
}

List<_ParentProfile> _seedProfiles() {
  return const [
    _ParentProfile(
      id: 'p1',
      name: 'Miriam',
      age: 34,
      city: 'Berlin',
      bio: 'Ich suche Eltern fuer gemeinsame Wochenendaktivitaeten und ehrlichen Austausch.',
      interests: ['Spielplatz', 'Outdoor', 'Familienzeit', 'Bildung'],
      languages: ['Deutsch', 'Englisch'],
      valuesFocus: ['Gewaltfrei', 'Empathie', 'Inklusion'],
      childAges: ['3-5', '6-9'],
      familyForm: 'Kernfamilie',
      verificationLevel: _VerificationLevel.recommended,
    ),
    _ParentProfile(
      id: 'p2',
      name: 'Sibel',
      age: 37,
      city: 'Koeln',
      bio: 'Alleinerziehend, offen fuer neue Freundschaften mit Eltern in aehnlicher Situation.',
      interests: ['Gesundheit', 'Bildung', 'Kreativ'],
      languages: ['Deutsch', 'Tuerkisch'],
      valuesFocus: ['Respekt', 'Offenheit', 'Empathie'],
      childAges: ['6-9', '10-13'],
      familyForm: 'Alleinerziehend',
      verificationLevel: _VerificationLevel.checked,
    ),
    _ParentProfile(
      id: 'p3',
      name: 'Jonas',
      age: 40,
      city: 'Hamburg',
      bio: 'Wir sind eine Patchwork-Familie und suchen entspannte Eltern fuer Spieltreffen.',
      interests: ['Sport', 'Outdoor', 'Spielplatz'],
      languages: ['Deutsch'],
      valuesFocus: ['Gewaltfrei', 'Tradition', 'Respekt'],
      childAges: ['0-2', '3-5'],
      familyForm: 'Patchwork',
      verificationLevel: _VerificationLevel.basic,
    ),
    _ParentProfile(
      id: 'p4',
      name: 'Lina',
      age: 32,
      city: 'Muenchen',
      bio: 'Ich liebe Lernideen fuer Kinder und suche Eltern fuer kleine Bildungsprojekte.',
      interests: ['Bildung', 'Kreativ', 'Familienzeit'],
      languages: ['Deutsch', 'Franzoesisch', 'Englisch'],
      valuesFocus: ['Inklusion', 'Offenheit', 'Empathie'],
      childAges: ['6-9'],
      familyForm: 'Kernfamilie',
      verificationLevel: _VerificationLevel.recommended,
    ),
    _ParentProfile(
      id: 'p5',
      name: 'Baran',
      age: 35,
      city: 'Dortmund',
      bio: 'Vater von zwei Kids, interessiert an gewaltfreier Kommunikation und Community.',
      interests: ['Gesundheit', 'Familienzeit', 'Sport'],
      languages: ['Deutsch', 'Kurdisch'],
      valuesFocus: ['Gewaltfrei', 'Respekt', 'Empathie'],
      childAges: ['3-5', '10-13'],
      familyForm: 'Kernfamilie',
      verificationLevel: _VerificationLevel.checked,
    ),
  ];
}