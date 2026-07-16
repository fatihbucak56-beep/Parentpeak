import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:parentpeak/logic/auth_service.dart';
import 'package:parentpeak/logic/backend_service_factory.dart';
import 'package:parentpeak/logic/product_metrics_service.dart';
import 'package:parentpeak/logic/weekly_impulse_service.dart';
import 'package:parentpeak/models_and_widgets/weekly_impulse_feature.dart';
import 'package:parentpeak/models_and_widgets/development_schema_feature.dart';
import 'package:parentpeak/ui/calendar_screen.dart';
import 'package:parentpeak/ui/chat_screen.dart';

class EntwicklungImpulseScreen extends StatefulWidget {
  final int initialTabIndex;

  const EntwicklungImpulseScreen({
    super.key,
    this.initialTabIndex = 0,
  });

  @override
  State<EntwicklungImpulseScreen> createState() =>
      _EntwicklungImpulseScreenState();
}

class _EntwicklungImpulseScreenState extends State<EntwicklungImpulseScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final FlutterTts _tts = FlutterTts();
  final WeeklyImpulseService _weeklyImpulseService =
      BackendServiceFactory.createWeeklyImpulseService();

  WeeklyImpulse? _weeklyImpulse;
  WeeklyImpulseVerificationStatus? _verificationStatus;
  bool _isLoading = true;
  String? _loadErrorMessage;
  String? _nonBlockingNotice;

  bool get _showModerationTools {
    final email = AuthService.instance.currentUser?.email.toLowerCase().trim() ?? '';
    return kDebugMode || email.endsWith('@parentpeak.de') || email.endsWith('@parentpeak.com');
  }

  String get _viewerUserId =>
      AuthService.instance.currentUser?.uid.trim().isNotEmpty == true
          ? AuthService.instance.currentUser!.uid.trim()
          : 'guest_local_parent';

  String get _viewerDisplayName {
    final name = AuthService.instance.currentUser?.displayName.trim() ?? '';
    return name.isEmpty ? 'Ein Elternteil aus der Community' : name;
  }

  String get _viewerEmail {
    final email = AuthService.instance.currentUser?.email.trim() ?? '';
    return email.isEmpty ? 'guest@parentpeak.local' : email;
  }

  String _formatModerationDate(DateTime? value) {
    if (value == null) {
      return 'unbekannt';
    }

    final local = value.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year.toString();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day.$month.$year, $hour:$minute';
  }

  String _describeLastModerationAction(WeeklyImpulseModerationReport report) {
    switch (report.lastAction) {
      case 'resolved':
        return 'Zuletzt als bearbeitet markiert';
      case 'hidden':
        return 'Zuletzt global ausgeblendet';
      case 'restored':
        return 'Zuletzt wieder freigegeben';
      default:
        return 'Gemeldet';
    }
  }

  Future<String?> _askModerationNote({
    required String title,
    required String hintText,
    String initialValue = '',
  }) async {
    final controller = TextEditingController(text: initialValue);
    String? result;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                'Optional, aber fuer spaetere Nachvollziehbarkeit sehr hilfreich.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                minLines: 3,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: 'Moderationsnotiz',
                  hintText: hintText,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    result = controller.text.trim();
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Weiter'),
                ),
              ),
            ],
          ),
        );
      },
    );

    controller.dispose();
    return result;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 1),
    );
    _loadImpulse();
  }

  @override
  void dispose() {
    _tts.stop();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadImpulse() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _loadErrorMessage = null;
        _nonBlockingNotice = null;
      });
    }

    try {
      final impulse = await _weeklyImpulseService.fetchWeeklyImpulse(
        viewerUserId: _viewerUserId,
      );

      WeeklyImpulseVerificationStatus? verificationStatus;
      try {
        verificationStatus = await _weeklyImpulseService.fetchVerificationStatus(
          userId: _viewerUserId,
          email: _viewerEmail,
        );
      } catch (_) {
        _nonBlockingNotice =
            'Community-Status ist gerade eingeschraenkt. Der Wochenimpuls bleibt nutzbar.';
      }

      if (!mounted) return;
      setState(() {
        _weeklyImpulse = impulse;
        _verificationStatus = verificationStatus;
        _isLoading = false;
        _loadErrorMessage = null;
      });
    } catch (e) {
      debugPrint('EntwicklungImpulseScreen._loadImpulse(): failed: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadErrorMessage = _friendlyLoadErrorMessage(e);
      });
    }
  }

  String _friendlyLoadErrorMessage(Object error) {
    if (error is TimeoutException) {
      return 'Der Wochenimpuls braucht gerade zu lange. Bitte spaeter erneut versuchen.';
    }
    if (error is SocketException) {
      return 'Keine stabile Verbindung. Bitte Internet pruefen oder spaeter erneut laden.';
    }

    final message = error.toString().toLowerCase();
    if (message.contains('timeout')) {
      return 'Der Wochenimpuls hat ein Zeitlimit erreicht. Bitte erneut versuchen.';
    }
    if (message.contains('socket') ||
        message.contains('network') ||
        message.contains('connection')) {
      return 'Netzwerkproblem erkannt. Bitte Verbindung pruefen und erneut laden.';
    }
    if (message.contains('backend')) {
      return 'Der Dienst ist gerade eingeschraenkt verfuegbar. Bitte spaeter erneut versuchen.';
    }
    return 'Wochenimpuls ist aktuell nicht verfuegbar. Bitte spaeter erneut versuchen.';
  }

  Future<void> _openChatFallback() async {
    await ProductMetricsService.instance.recordWeeklyImpulseFallbackRouteTap(
      from: 'weekly_impulse',
      to: 'chat',
      userId: AuthService.instance.currentUser?.uid,
    );
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ChatScreen()),
    );
  }

  Future<void> _openCalendarFallback() async {
    await ProductMetricsService.instance.recordWeeklyImpulseFallbackRouteTap(
      from: 'weekly_impulse',
      to: 'calendar',
      userId: AuthService.instance.currentUser?.uid,
    );
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CalendarScreen()),
    );
  }

  Future<void> _createCommunityPost(
    String title,
    String body,
    String role,
  ) async {
    final impulse = _weeklyImpulse;
    if (impulse == null) {
      throw StateError('Weekly impulse unavailable');
    }

    await _weeklyImpulseService.createCommunityPost(
      impulseId: impulse.id,
      title: title,
      body: body,
      authorName: _viewerDisplayName,
      authorUserId: _viewerUserId,
      authorEmail: _viewerEmail,
      role: role,
    );
    await _loadImpulse();
  }

  Future<void> _toggleCommunityLike(String postId, bool currentlyLiked) async {
    final impulse = _weeklyImpulse;
    if (impulse == null) {
      throw StateError('Weekly impulse unavailable');
    }

    await _weeklyImpulseService.setCommunityLike(
      impulseId: impulse.id,
      postId: postId,
      userId: _viewerUserId,
      isLiked: !currentlyLiked,
    );
    await _loadImpulse();
  }

  Future<void> _addCommunityComment(String postId, String comment) async {
    final impulse = _weeklyImpulse;
    if (impulse == null) {
      throw StateError('Weekly impulse unavailable');
    }

    await _weeklyImpulseService.addCommunityComment(
      impulseId: impulse.id,
      postId: postId,
      authorName: _viewerDisplayName,
      role: 'Elternteil',
      comment: comment,
    );
    await _loadImpulse();
  }

  Future<void> _reportCommunityPost(String postId, String reason) async {
    final impulse = _weeklyImpulse;
    if (impulse == null) {
      throw StateError('Weekly impulse unavailable');
    }

    await _weeklyImpulseService.reportCommunityPost(
      impulseId: impulse.id,
      postId: postId,
      reporterUserId: _viewerUserId,
      reporterName: _viewerDisplayName,
      reason: reason,
    );
    await _loadImpulse();
  }

  Future<void> _showVerificationSheet() async {
    final status = _verificationStatus;
    final verifiedProfile = status?.verifiedProfile;
    final latestRequest = status?.latestRequest;
    final roleTitleController = TextEditingController();
    final organizationController = TextEditingController();
    final noteController = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Fachprofil',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              if (status?.verified == true)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD1FAE5),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(
                        '${status!.verificationLabel.isEmpty ? 'Verifiziert' : status.verificationLabel} seit ${_formatModerationDate(status.verifiedAt)}',
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildVerificationInfoCard(
                      title: 'Fachprofil',
                      rows: [
                        if ((verifiedProfile?.displayName ?? '').isNotEmpty)
                          'Name: ${verifiedProfile!.displayName}',
                        if ((verifiedProfile?.roleTitle ?? '').isNotEmpty)
                          'Rolle: ${verifiedProfile!.roleTitle}',
                        if ((verifiedProfile?.organization ?? '').isNotEmpty)
                          'Einrichtung: ${verifiedProfile!.organization}',
                        if ((verifiedProfile?.reviewedBy ?? '').isNotEmpty)
                          'Freigegeben von: ${verifiedProfile!.reviewedBy}',
                      ],
                    ),
                    if ((verifiedProfile?.reviewNote ?? '').isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildVerificationInfoCard(
                        title: 'Freigabehinweis',
                        rows: [verifiedProfile!.reviewNote],
                      ),
                    ],
                  ],
                )
              else if (status?.pendingRequest == true)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDE68A),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Text(
                        'Deine Verifizierungsanfrage ist eingegangen und wird geprueft.',
                      ),
                    ),
                    if (latestRequest != null) ...[
                      const SizedBox(height: 16),
                      _buildVerificationInfoCard(
                        title: 'Deine Anfrage',
                        rows: [
                          if (latestRequest.roleTitle.isNotEmpty)
                            'Rolle: ${latestRequest.roleTitle}',
                          if (latestRequest.organization.isNotEmpty)
                            'Einrichtung: ${latestRequest.organization}',
                          'Eingereicht: ${_formatModerationDate(latestRequest.createdAt)}',
                          if (latestRequest.note.isNotEmpty)
                            'Kurzinfo: ${latestRequest.note}',
                        ],
                      ),
                    ],
                  ],
                )
              else ...[
                Text(
                  'Beantrage ein verifiziertes Fach-Badge fuer paedagogische Beitraege.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: roleTitleController,
                  decoration: const InputDecoration(
                    labelText: 'Rolle / Qualifikation',
                    hintText: 'Zum Beispiel: Erzieherin, Familienberater',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: organizationController,
                  decoration: const InputDecoration(
                    labelText: 'Einrichtung / Kontext',
                    hintText: 'Zum Beispiel: Kita Sonnenschein',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteController,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Kurzinfo',
                    hintText: 'Welche Erfahrung oder Ausbildung bringst du mit?',
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () async {
                      await _weeklyImpulseService.createVerificationRequest(
                        userId: _viewerUserId,
                        email: _viewerEmail,
                        displayName: _viewerDisplayName,
                        roleTitle: roleTitleController.text.trim(),
                        organization: organizationController.text.trim(),
                        note: noteController.text.trim(),
                      );
                      if (!mounted) {
                        return;
                      }
                      await _loadImpulse();
                      if (!context.mounted) {
                        return;
                      }
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.verified_user_outlined),
                    label: const Text('Verifizierung anfragen'),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );

    roleTitleController.dispose();
    organizationController.dispose();
    noteController.dispose();
  }

  Widget _buildVerificationInfoCard({
    required String title,
    required List<String> rows,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          ...rows.map(
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(row),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showVerificationReviewSheet() async {
    List<WeeklyImpulseVerificationRequest> requests =
        const <WeeklyImpulseVerificationRequest>[];
    var isLoading = true;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        Future<void> loadRequests(StateSetter setModalState) async {
          final fetched = await _weeklyImpulseService.fetchVerificationRequests(
            status: 'pending',
            reviewerEmail: _viewerEmail,
          );
          setModalState(() {
            requests = fetched;
            isLoading = false;
          });
        }

        return StatefulBuilder(
          builder: (context, setModalState) {
            if (isLoading) {
              loadRequests(setModalState);
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Fachverifizierung pruefen',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  if (isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (requests.isEmpty)
                    const Text('Keine offenen Anfragen.')
                  else
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 460),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: requests.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final request = requests[index];
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  request.displayName,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 6),
                                Text('${request.roleTitle}  •  ${request.organization}'),
                                if (request.note.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(request.note),
                                ],
                                const SizedBox(height: 12),
                                FilledButton.icon(
                                  onPressed: () async {
                                    final note = await _askModerationNote(
                                      title: 'Fachprofil freigeben',
                                      hintText: 'Zum Beispiel: Ausbildung geprueft, Fachbadge freigegeben.',
                                      initialValue: request.reviewNote,
                                    );
                                    if (note == null) {
                                      return;
                                    }
                                    await _weeklyImpulseService.approveVerificationRequest(
                                      requestId: request.id,
                                      reviewerName: _viewerDisplayName,
                                      reviewerEmail: _viewerEmail,
                                      reviewNote: note,
                                      verificationLabel: 'Verifizierte Fachstimme',
                                    );
                                    if (!mounted) {
                                      return;
                                    }
                                    await _loadImpulse();
                                    if (!context.mounted) {
                                      return;
                                    }
                                    await loadRequests(setModalState);
                                  },
                                  icon: const Icon(Icons.verified_rounded),
                                  label: const Text('Freigeben'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showModerationPanel() async {
    final impulse = _weeklyImpulse;
    if (impulse == null) {
      return;
    }

    List<WeeklyImpulseModerationReport> reports = const <WeeklyImpulseModerationReport>[];
    var isLoadingReports = true;
    String? errorMessage;
    String selectedFilter = 'offen';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        Future<void> loadReports(StateSetter setModalState) async {
          setModalState(() {
            isLoadingReports = true;
            errorMessage = null;
          });
          try {
            final fetched = await _weeklyImpulseService.fetchModerationReports(
              impulseId: impulse.id,
              moderatorEmail: _viewerEmail,
              includeResolved: true,
            );
            setModalState(() {
              reports = fetched;
              isLoadingReports = false;
            });
          } catch (e) {
            setModalState(() {
              errorMessage = 'Moderationsdaten konnten nicht geladen werden.';
              isLoadingReports = false;
            });
          }
        }

        return StatefulBuilder(
          builder: (context, setModalState) {
            if (isLoadingReports && reports.isEmpty && errorMessage == null) {
              loadReports(setModalState);
            }

            final visibleReports = reports.where((report) {
              switch (selectedFilter) {
                case 'bearbeitet':
                  return report.isResolved;
                case 'ausgeblendet':
                  return report.hiddenByModeration;
                default:
                  return !report.isResolved;
              }
            }).toList();

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Moderation live',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      IconButton(
                        onPressed: () => loadReports(setModalState),
                        icon: const Icon(Icons.refresh_rounded),
                        tooltip: 'Neu laden',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Hier siehst du Meldungen aus dem Backend und kannst Beitraege global ausblenden, freigeben oder als bearbeitet markieren.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      ChoiceChip(
                        label: const Text('Offen'),
                        selected: selectedFilter == 'offen',
                        onSelected: (_) {
                          setModalState(() => selectedFilter = 'offen');
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Bearbeitet'),
                        selected: selectedFilter == 'bearbeitet',
                        onSelected: (_) {
                          setModalState(() => selectedFilter = 'bearbeitet');
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Ausgeblendet'),
                        selected: selectedFilter == 'ausgeblendet',
                        onSelected: (_) {
                          setModalState(() => selectedFilter = 'ausgeblendet');
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (isLoadingReports && reports.isEmpty)
                    const Center(child: CircularProgressIndicator())
                  else if (errorMessage != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(errorMessage!),
                    )
                  else if (visibleReports.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(
                        selectedFilter == 'bearbeitet'
                            ? 'Keine bearbeiteten Meldungen.'
                            : selectedFilter == 'ausgeblendet'
                                ? 'Keine global ausgeblendeten Beitraege.'
                                : 'Keine offenen Meldungen.',
                      ),
                    )
                  else
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 460),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: visibleReports.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final report = visibleReports[index];
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        report.postTitle,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: report.hiddenByModeration
                                            ? const Color(0xFFFECACA)
                                            : report.isResolved
                                                ? const Color(0xFFD1FAE5)
                                                : const Color(0xFFFDE68A),
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: Text(report.hiddenByModeration
                                          ? 'Ausgeblendet'
                                          : report.isResolved
                                              ? 'Bearbeitet'
                                              : 'Offen'),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${report.postAuthorName}  •  ${report.postRole}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Grund: ${report.reason}',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Gemeldet von ${report.reporterName}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Gemeldet am ${_formatModerationDate(report.createdAt)}',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                                ),
                                if (report.moderatorNote.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'Moderationsnotiz: ${report.moderatorNote}',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                                  ),
                                ],
                                if (report.hiddenByModeration) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    'Global ausgeblendet${report.hiddenBy.isNotEmpty ? ' von ${report.hiddenBy}' : ''} am ${_formatModerationDate(report.hiddenAt)}',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                                if (report.isResolved) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    'Bearbeitet${report.resolvedBy.isNotEmpty ? ' von ${report.resolvedBy}' : ''} am ${_formatModerationDate(report.resolvedAt)}',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                                if (report.lastActionAt != null) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .surface,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .outlineVariant,
                                      ),
                                    ),
                                    child: Text(
                                      '${_describeLastModerationAction(report)} am ${_formatModerationDate(report.lastActionAt)}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 14),
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: [
                                    FilledButton.icon(
                                      onPressed: report.isResolved
                                          ? null
                                          : () async {
                                              final note = await _askModerationNote(
                                                title: 'Meldung abschliessen',
                                                hintText: 'Zum Beispiel: Beitrag geprueft, im Ton grenzwertig, aber stehen gelassen.',
                                                initialValue: report.moderatorNote,
                                              );
                                              if (note == null || !mounted) {
                                                return;
                                              }
                                              await _weeklyImpulseService.resolveModerationReport(
                                                impulseId: impulse.id,
                                                reportId: report.id,
                                                moderatorName: _viewerDisplayName,
                                                moderatorEmail: _viewerEmail,
                                                moderatorNote: note,
                                              );
                                              if (!mounted) {
                                                return;
                                              }
                                              await _loadImpulse();
                                              if (!context.mounted) {
                                                return;
                                              }
                                              await loadReports(setModalState);
                                            },
                                      icon: const Icon(Icons.check_circle_outline_rounded),
                                      label: const Text('Bearbeitet'),
                                    ),
                                    OutlinedButton.icon(
                                      onPressed: () async {
                                        final note = await _askModerationNote(
                                          title: report.hiddenByModeration
                                              ? 'Beitrag wieder freigeben'
                                              : 'Beitrag global ausblenden',
                                          hintText: report.hiddenByModeration
                                              ? 'Zum Beispiel: Nach Pruefung wieder freigegeben.'
                                              : 'Zum Beispiel: Vorlaeufig ausgeblendet bis fachliche Pruefung abgeschlossen ist.',
                                          initialValue: report.moderatorNote,
                                        );
                                        if (note == null || !mounted) {
                                          return;
                                        }
                                        await _weeklyImpulseService.setCommunityPostHidden(
                                          impulseId: impulse.id,
                                          postId: report.postId,
                                          moderatorName: _viewerDisplayName,
                                          moderatorEmail: _viewerEmail,
                                          hidden: !report.hiddenByModeration,
                                          moderatorNote: note,
                                          reportId: report.id,
                                        );
                                        if (!mounted) {
                                          return;
                                        }
                                        await _loadImpulse();
                                        if (!context.mounted) {
                                          return;
                                        }
                                        await loadReports(setModalState);
                                      },
                                      icon: Icon(report.hiddenByModeration
                                          ? Icons.visibility_rounded
                                          : Icons.visibility_off_rounded),
                                      label: Text(report.hiddenByModeration
                                          ? 'Wieder freigeben'
                                          : 'Global ausblenden'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _playAudio() async {
    final text = _weeklyImpulse?.audioScript;
    if (text == null || text.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kein Audio-Skript verfuegbar.')),
      );
      return;
    }
    await _tts.stop();
    if (!mounted) return;
    try {
      final languageCode = Localizations.localeOf(context).languageCode;
      await _tts.setLanguage(_resolveTtsLocale(languageCode));
    } catch (e) {
      debugPrint('EntwicklungImpulseScreen._playAudio(): locale setup failed: $e');
      await _tts.setLanguage('de-DE');
    }
    await _tts.setPitch(1.0);
    await _tts.setSpeechRate(0.47);
    await _tts.speak(text);
  }

  String _resolveTtsLocale(String code) {
    switch (code) {
      case 'en':
        return 'en-US';
      case 'fr':
        return 'fr-FR';
      case 'es':
        return 'es-ES';
      case 'tr':
        return 'tr-TR';
      case 'ar':
        return 'ar-SA';
      case 'fa':
        return 'fa-IR';
      default:
        return 'de-DE';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Impulse & Entwicklung'),
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            onPressed: _showVerificationSheet,
            icon: Icon(
              _verificationStatus?.verified == true
                  ? Icons.verified_rounded
                  : Icons.verified_user_outlined,
            ),
            tooltip: 'Fachprofil',
          ),
          if (_showModerationTools)
            IconButton(
              onPressed: _showModerationPanel,
              icon: const Icon(Icons.admin_panel_settings_outlined),
              tooltip: 'Moderation',
            ),
          if (_showModerationTools)
            IconButton(
              onPressed: _showVerificationReviewSheet,
              icon: const Icon(Icons.fact_check_outlined),
              tooltip: 'Verifizierung pruefen',
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: _buildTopHeader(theme),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: TabBar(
                controller: _tabController,
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                labelColor: theme.colorScheme.onPrimaryContainer,
                unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                tabs: const [
                  Tab(
                    icon: Icon(Icons.wb_sunny_rounded),
                    text: 'Wochenimpuls',
                  ),
                  Tab(
                    icon: Icon(Icons.checklist_rtl_rounded),
                    text: 'Entwicklung',
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildWochenimpulsTab(theme),
                const SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: DevelopmentSchemaCard(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.tertiary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: Colors.white.withValues(alpha: 0.18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
            ),
            child: const Stack(
              alignment: Alignment.center,
              children: [
                Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 26),
                Positioned(
                  right: 8,
                  bottom: 7,
                  child: Icon(Icons.trending_up_rounded,
                      color: Colors.white, size: 14),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Impulse & Entwicklung',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ein eigener Bereich wie Kalender und Organisation.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWochenimpulsTab(ThemeData theme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_weeklyImpulse == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off_rounded,
                  size: 56, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(height: 16),
              Text(
                'Wochenimpuls nicht verfuegbar',
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _loadErrorMessage ?? 'Bitte Backend-Verbindung pruefen.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () {
                  _loadImpulse();
                },
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Erneut laden'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () {
                  _tabController.animateTo(1);
                },
                icon: const Icon(Icons.insights_rounded),
                label: const Text('Mit Entwicklung weitermachen'),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: _openChatFallback,
                    icon: const Icon(Icons.tips_and_updates_rounded),
                    label: const Text('Zur KI-Beratung'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _openCalendarFallback,
                    icon: const Icon(Icons.calendar_month_rounded),
                    label: const Text('Zum Kalender'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadImpulse,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_nonBlockingNotice != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _nonBlockingNotice!,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            WeeklyImpulseCard(
              impulse: _weeklyImpulse!,
              onAudioPressed: _playAudio,
              onCreateCommunityPost: _createCommunityPost,
              onToggleLikePost: _toggleCommunityLike,
              onAddComment: _addCommunityComment,
              onReportPost: _reportCommunityPost,
            ),
          ],
        ),
      ),
    );
  }
}
