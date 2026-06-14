import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart' as pdf;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'development_schema_data.dart';

const Map<String, String> kMilestoneStatusLabels = {
  'NOCH_NICHT': 'Noch nicht',
  'ANSATZWEISE': 'Ansatzweise',
  'WEITGEHEND': 'Weitgehend',
  'ZUVERLAESSIG': 'Zuverlaessig',
};

class _ChildProfile {
  final String id;
  final String label;

  const _ChildProfile({required this.id, required this.label});
}

const List<_ChildProfile> _childProfiles = [
  _ChildProfile(id: 'kind_1', label: 'Kind 1'),
  _ChildProfile(id: 'kind_2', label: 'Kind 2'),
  _ChildProfile(id: 'kind_3', label: 'Kind 3'),
];

class _PhaseTheme {
  final Color color;
  final IconData icon;

  const _PhaseTheme({required this.color, required this.icon});
}

class _StoredMilestoneProgress {
  final String status;
  final DateTime updatedAt;

  const _StoredMilestoneProgress({
    required this.status,
    required this.updatedAt,
  });

  factory _StoredMilestoneProgress.fromJson(Map<String, dynamic> json) {
    return _StoredMilestoneProgress(
      status: json['status'] as String? ?? 'NOCH_NICHT',
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toJson() => {
        'status': status,
        'updatedAt': updatedAt.toIso8601String(),
      };
}

  class _ProgressEvent {
    final String code;
    final String title;
    final String status;
    final DateTime updatedAt;

    const _ProgressEvent({
      required this.code,
      required this.title,
      required this.status,
      required this.updatedAt,
    });

    factory _ProgressEvent.fromJson(Map<String, dynamic> json) {
      return _ProgressEvent(
        code: json['code'] as String? ?? '',
        title: json['title'] as String? ?? '',
        status: json['status'] as String? ?? 'NOCH_NICHT',
        updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
      );
    }

    Map<String, dynamic> toJson() => {
          'code': code,
          'title': title,
          'status': status,
          'updatedAt': updatedAt.toIso8601String(),
        };
  }

class DevelopmentSchemaCard extends StatefulWidget {
  final String childId;

  const DevelopmentSchemaCard({super.key, this.childId = 'default'});

  @override
  State<DevelopmentSchemaCard> createState() => _DevelopmentSchemaCardState();
}

class _DevelopmentSchemaCardState extends State<DevelopmentSchemaCard> {
  int _selectedPhaseIndex = 0;
  String _selectedChildId = _childProfiles.first.id;
  bool _isLoading = true;
  Map<String, _StoredMilestoneProgress> _progressByCode = {};
  List<_ProgressEvent> _history = [];

  @override
  void initState() {
    super.initState();
    _loadSelectionAndProgress();
  }

  String _selectionStorageKey() =>
      'development_selected_child_${widget.childId}';

  String _storageKey() =>
      'development_progress_${widget.childId}_$_selectedChildId';

    String _historyKey() =>
      'development_progress_history_${widget.childId}_$_selectedChildId';

  Future<void> _loadSelectionAndProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final selectedChild = prefs.getString(_selectionStorageKey());

    if (selectedChild != null &&
        _childProfiles.any((profile) => profile.id == selectedChild)) {
      _selectedChildId = selectedChild;
    }

    await _loadProgress();
  }

  Future<void> _selectChild(String childId) async {
    if (_selectedChildId == childId) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectionStorageKey(), childId);

    if (!mounted) return;
    setState(() {
      _selectedChildId = childId;
      _isLoading = true;
    });

    await _loadProgress();
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey());
    final historyRaw = prefs.getString(_historyKey());
    final loaded = <String, _StoredMilestoneProgress>{};
    final loadedHistory = <_ProgressEvent>[];

    if (raw != null && raw.isNotEmpty) {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      for (final entry in decoded.entries) {
        final value = entry.value;
        if (value is Map<String, dynamic>) {
          loaded[entry.key] = _StoredMilestoneProgress.fromJson(value);
        }
      }
    }

    if (historyRaw != null && historyRaw.isNotEmpty) {
      final decodedHistory = jsonDecode(historyRaw) as List<dynamic>;
      for (final entry in decodedHistory) {
        if (entry is Map<String, dynamic>) {
          loadedHistory.add(_ProgressEvent.fromJson(entry));
        }
      }
      loadedHistory.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    }

    if (!mounted) return;
    setState(() {
      _progressByCode = loaded;
      _history = loadedHistory;
      _isLoading = false;
    });
  }

  Future<void> _setMilestoneStatus(
    DevelopmentMilestoneItem item,
    String status,
  ) async {
    final updated = Map<String, _StoredMilestoneProgress>.from(_progressByCode);
    updated[item.code] = _StoredMilestoneProgress(
      status: status,
      updatedAt: DateTime.now(),
    );

    setState(() {
      _progressByCode = updated;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey(),
      jsonEncode(updated.map((key, value) => MapEntry(key, value.toJson()))),
    );

    final updatedHistory = <_ProgressEvent>[
      _ProgressEvent(
        code: item.code,
        title: item.title,
        status: status,
        updatedAt: DateTime.now(),
      ),
      ..._history,
    ];
    await prefs.setString(
      _historyKey(),
      jsonEncode(updatedHistory.map((event) => event.toJson()).toList()),
    );

    if (!mounted) return;
    setState(() {
      _history = updatedHistory;
    });
  }

  String _formatDate(DateTime value) {
    final local = value.toLocal();
    return '${local.day.toString().padLeft(2, '0')}.${local.month.toString().padLeft(2, '0')}.${local.year}';
  }

  Future<void> _shareCurrentOverview() async {
    final phase = kDevelopmentMilestoneDatabase.phases[_selectedPhaseIndex];
    final childLabel = _childProfiles
        .firstWhere((profile) => profile.id == _selectedChildId)
        .label;
    final logoBytes = (await rootBundle.load('assets/images/neue logo.png'))
        .buffer
        .asUint8List();
    pw.ThemeData? pdfTheme;
    try {
      final baseFont = await PdfGoogleFonts.notoSansRegular();
      final boldFont = await PdfGoogleFonts.notoSansBold();
      pdfTheme = pw.ThemeData.withFont(
        base: baseFont,
        bold: boldFont,
      );
    } catch (_) {
      pdfTheme = null;
    }

    final document = pw.Document(
      theme: pdfTheme,
    );

    document.addPage(
      pw.MultiPage(
        pageFormat: pdf.PdfPageFormat.a4,
        header: (context) => pw.Container(),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Parentpeak',
            style: const pw.TextStyle(fontSize: 9),
          ),
        ),
        build: (context) => [
          pw.Center(
            child: pw.Column(
              children: [
                pw.Container(
                  width: 84,
                  height: 84,
                  decoration: pw.BoxDecoration(
                    borderRadius: pw.BorderRadius.circular(20),
                  ),
                  child: pw.Image(pw.MemoryImage(logoBytes), fit: pw.BoxFit.contain),
                ),
                pw.SizedBox(height: 14),
                pw.Text(
                  'Parentpeak',
                  style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  'Entwicklungsschema fuer Eltern',
                  style: const pw.TextStyle(fontSize: 13),
                ),
                pw.SizedBox(height: 16),
                pw.Text(
                  'Kind: $childLabel',
                  style: const pw.TextStyle(fontSize: 12),
                ),
                pw.Text(
                  'Phase: ${phase.ageRange} - ${phase.title}',
                  style: const pw.TextStyle(fontSize: 12),
                ),
                pw.Text(
                  'Fortschritt: ${(_phaseProgress(phase) * 100).round()}%',
                  style: const pw.TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 18),
          pw.Divider(),
          pw.SizedBox(height: 10),
          pw.Text(
            'Statusverteilung',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          pw.Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _phaseStatusCounts(phase).entries.map((entry) {
              final label = kMilestoneStatusLabels[entry.key] ?? entry.key;
              return pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: pw.BoxDecoration(
                  border: const pw.Border.fromBorderSide(
                    pw.BorderSide(color: pdf.PdfColor.fromInt(0xFFCCCCCC)),
                  ),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Text('$label: ${entry.value}'),
              );
            }).toList(),
          ),
          pw.SizedBox(height: 12),
          ...phase.categories.map((category) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  category.name,
                  style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 4),
                ...category.items.map((item) {
                  final status = kMilestoneStatusLabels[_statusFor(item.code)] ?? _statusFor(item.code);
                  return pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 4),
                    child: pw.Text('- ${item.code} ${item.title}: $status'),
                  );
                }),
                pw.SizedBox(height: 8),
              ],
            );
          }),
          if (_history.isNotEmpty) ...[
            pw.Text(
              'Letzte Aenderungen',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 6),
            ..._history.take(5).map((event) {
              final status = kMilestoneStatusLabels[event.status] ?? event.status;
              return pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 4),
                child: pw.Text(
                  '- ${event.code} ${event.title}: $status • ${_formatDate(event.updatedAt)}',
                ),
              );
            }),
          ],
        ],
      ),
    );

    await Printing.sharePdf(
      bytes: await document.save(),
      filename: 'entwicklungsschema_${_selectedChildId}_${phase.id}.pdf',
    );
  }

  String _statusFor(String code) {
    return _progressByCode[code]?.status ?? 'NOCH_NICHT';
  }

  double _phaseProgress(DevelopmentPhase phase) {
    final total = phase.categories.fold<int>(0, (sum, category) => sum + category.items.length);
    if (total == 0) return 0;

    final completed = phase.categories.expand((category) => category.items).where((item) {
      final status = _statusFor(item.code);
      return status == 'WEITGEHEND' || status == 'ZUVERLAESSIG';
    }).length;

    return completed / total;
  }

  Map<String, int> _phaseStatusCounts(DevelopmentPhase phase) {
    final counts = <String, int>{
      'NOCH_NICHT': 0,
      'ANSATZWEISE': 0,
      'WEITGEHEND': 0,
      'ZUVERLAESSIG': 0,
    };

    for (final item in phase.categories.expand((category) => category.items)) {
      counts[_statusFor(item.code)] = (counts[_statusFor(item.code)] ?? 0) + 1;
    }

    return counts;
  }

  _PhaseTheme _phaseThemeForIndex(int index) {
    switch (index) {
      case 0:
        return const _PhaseTheme(color: Color(0xFF0EA5E9), icon: Icons.baby_changing_station_rounded);
      case 1:
        return const _PhaseTheme(color: Color(0xFF16A34A), icon: Icons.child_care_rounded);
      case 2:
        return const _PhaseTheme(color: Color(0xFFF97316), icon: Icons.park_rounded);
      case 3:
        return const _PhaseTheme(color: Color(0xFF2563EB), icon: Icons.school_rounded);
      case 4:
      default:
        return const _PhaseTheme(color: Color(0xFF9333EA), icon: Icons.groups_rounded);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final phase = kDevelopmentMilestoneDatabase.phases[_selectedPhaseIndex];
    final phaseTheme = _phaseThemeForIndex(_selectedPhaseIndex);

    if (_isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              ),
              SizedBox(width: 12),
              Expanded(child: Text('Entwicklungsschema wird geladen...')),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Entwicklungsschema fuer Eltern',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Die Phasen reichen von 0 bis 18 Jahren. Waehle das passende Alter und bewerte die Meilensteine fuer das aktive Kind.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                Text(
                  'Kind waehlen',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 44,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _childProfiles.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final child = _childProfiles[index];
                      return ChoiceChip(
                        selected: child.id == _selectedChildId,
                        label: Text(child.label),
                        onSelected: (_) => _selectChild(child.id),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: _shareCurrentOverview,
                    icon: const Icon(Icons.share_rounded),
                    label: const Text('Uebersicht teilen'),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: kMilestoneStatusLabels.values
                      .map((label) => Chip(label: Text(label)))
                      .toList(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: kDevelopmentMilestoneDatabase.phases.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final currentPhase = kDevelopmentMilestoneDatabase.phases[index];
              return ChoiceChip(
                selected: index == _selectedPhaseIndex,
                label: Text(currentPhase.ageRange),
                onSelected: (_) {
                  setState(() {
                    _selectedPhaseIndex = index;
                  });
                },
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: phaseTheme.color.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        phaseTheme.icon,
                        color: phaseTheme.color,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            phase.title,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            phase.ageRange,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(value: _phaseProgress(phase)),
                const SizedBox(height: 8),
                Text(
                  'Fortschritt: ${(_phaseProgress(phase) * 100).round()}%',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _phaseStatusCounts(phase).entries.map((entry) {
                    final label = kMilestoneStatusLabels[entry.key] ?? entry.key;
                    return Chip(
                      label: Text('$label: ${entry.value}'),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),
                Text(
                  'Kindgerechte Formulierungen fuer Eltern',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Die Formulierungen sind bewusst alltagsnah gehalten. So kannst du schneller einschaetzen, was dein Kind gerade schon zeigt oder noch braucht.',
                  style: theme.textTheme.bodyMedium,
                ),
                if (_history.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text(
                    'Letzte Aenderungen fuer ${_childProfiles.firstWhere((profile) => profile.id == _selectedChildId).label}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._history.take(3).map((event) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        '${event.code} • ${event.title} → ${kMilestoneStatusLabels[event.status] ?? event.status} • ${event.updatedAt.toLocal().day.toString().padLeft(2, '0')}.${event.updatedAt.toLocal().month.toString().padLeft(2, '0')}.${event.updatedAt.toLocal().year}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        ...phase.categories.map((category) {
          return Card(
            child: ExpansionTile(
              title: Text(
                category.name,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: phaseTheme.color,
                ),
              ),
              subtitle: Text('${category.items.length} Kriterien'),
              childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              children: category.items.map((item) {
                final selectedStatus = _statusFor(item.code);
                final stored = _progressByCode[item.code];

                return Container(
                  margin: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${item.code}  ${item.title}',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(item.description),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.checklist_rounded,
                              color: phaseTheme.color,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: kMilestoneStatusLabels.entries.map((entry) {
                            final isSelected = selectedStatus == entry.key;
                            return ChoiceChip(
                              selected: isSelected,
                              label: Text(entry.value),
                              onSelected: (_) => _setMilestoneStatus(item, entry.key),
                            );
                          }).toList(),
                        ),
                        if (stored != null && stored.updatedAt.millisecondsSinceEpoch > 0) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Zuletzt aktualisiert: ${stored.updatedAt.toLocal().day.toString().padLeft(2, '0')}.${stored.updatedAt.toLocal().month.toString().padLeft(2, '0')}.${stored.updatedAt.toLocal().year}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        }),
      ],
    );
  }
}

