import 'package:trusted_circle_demo/models/meetup_chat.dart';

class MeetupChatService {
  static final Map<String, List<MeetupChatMessage>> _chatMessages = {};
  static final List<MeetupChatReport> _reports = [];

  // Hole Chat-Nachrichten für ein Event
  Future<List<MeetupChatMessage>> getMessages(String eventId) async {
    await Future.delayed(Duration(milliseconds: 300));
    return _chatMessages[eventId] ?? [];
  }

  // Sende Nachricht
  Future<MeetupChatMessage> sendMessage({
    required String eventId,
    required String userId,
    required String userName,
    required String userAvatarUrl,
    required String content,
    bool isHost = false,
  }) async {
    await Future.delayed(Duration(milliseconds: 400));

    final message = MeetupChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      eventId: eventId,
      userId: userId,
      userName: userName,
      userAvatarUrl: userAvatarUrl,
      content: content,
      timestamp: DateTime.now(),
      isHost: isHost,
    );

    if (!_chatMessages.containsKey(eventId)) {
      _chatMessages[eventId] = [];
    }

    _chatMessages[eventId]!.add(message);
    return message;
  }

  // Lösche Nachricht (nur Hoster oder Admin)
  Future<bool> deleteMessage(String eventId, String messageId) async {
    await Future.delayed(Duration(milliseconds: 300));

    if (_chatMessages.containsKey(eventId)) {
      final originalLength = _chatMessages[eventId]!.length;
      _chatMessages[eventId]!.removeWhere((m) => m.id == messageId);
      return _chatMessages[eventId]!.length < originalLength;
    }
    return false;
  }

  // Melde Nachricht
  Future<MeetupChatReport> reportMessage({
    required String reportedMessageId,
    required String reporterId,
    required String reason,
    String? description,
  }) async {
    await Future.delayed(Duration(milliseconds: 500));

    final report = MeetupChatReport(
      id: 'report_${DateTime.now().millisecondsSinceEpoch}',
      reportedMessageId: reportedMessageId,
      reporterId: reporterId,
      reason: reason,
      description: description,
      reportedAt: DateTime.now(),
    );

    _reports.add(report);
    return report;
  }

  // Hole alle Reports
  Future<List<MeetupChatReport>> getAllReports() async {
    await Future.delayed(Duration(milliseconds: 300));
    return List.from(_reports);
  }

  // Hole Reports für ein Event
  Future<List<MeetupChatReport>> getReportsForEvent(String eventId) async {
    await Future.delayed(Duration(milliseconds: 300));

    // Finde alle message IDs für dieses Event
    final eventMessages = _chatMessages[eventId] ?? [];
    final eventMessageIds = eventMessages.map((m) => m.id).toSet();

    return _reports
        .where((r) => eventMessageIds.contains(r.reportedMessageId))
        .toList();
  }

  // Prüfe ob User Zugriff auf Chat hat (bestätigter Teilnehmer oder Host)
  Future<bool> hasAccessToChat({
    required String eventId,
    required String userId,
    required String? hosterId,
  }) async {
    // In echtem System würde hier geprüft, ob User genehmigter Teilnehmer ist
    return userId == hosterId; // Vereinfachte Logik für Demo
  }
}
