import 'package:trusted_circle_demo/config/api_config.dart';
import 'package:trusted_circle_demo/logic/backend_api_client.dart';
import 'package:trusted_circle_demo/logic/backend_service_factory.dart';
import 'package:trusted_circle_demo/models/meetup_chat.dart';

class MeetupChatService {
  MeetupChatService({BackendApiClient? apiClient})
      : _apiClient = apiClient ?? BackendServiceFactory.createApiClient();

  static final Map<String, List<MeetupChatMessage>> _chatMessages = {};
  static final List<MeetupChatReport> _reports = [];

  final BackendApiClient? _apiClient;

  bool get isBackendEnabled => _apiClient != null;

  void _storeMessages(String eventId, List<MeetupChatMessage> items) {
    _chatMessages[eventId] = List<MeetupChatMessage>.from(items);
  }

  void _upsertMessage(String eventId, MeetupChatMessage item) {
    final items = _chatMessages[eventId] ?? <MeetupChatMessage>[];
    final index = items.indexWhere((message) => message.id == item.id);
    if (index == -1) {
      items.add(item);
    } else {
      items[index] = item;
    }
    _chatMessages[eventId] = items;
  }

  void _upsertReport(MeetupChatReport report) {
    final index = _reports.indexWhere((item) => item.id == report.id);
    if (index == -1) {
      _reports.add(report);
    } else {
      _reports[index] = report;
    }
  }

  Future<List<MeetupChatMessage>> getMessages(String eventId) async {
    if (_apiClient != null) {
      try {
        final payload = await _apiClient!.getJson('/events/$eventId/chat/messages');
        if (payload is Map<String, dynamic> && payload['items'] is List) {
          final items = (payload['items'] as List)
              .whereType<Map>()
              .map((item) => MeetupChatMessage.fromJson(Map<String, dynamic>.from(item)))
              .toList();
          _storeMessages(eventId, items);
          return items;
        }
      } catch (_) {
        // fallback below
      }
    }

    await Future.delayed(const Duration(milliseconds: 300));
    return _chatMessages[eventId] ?? [];
  }

  Future<MeetupChatMessage> sendMessage({
    required String eventId,
    required String userId,
    required String userName,
    required String userAvatarUrl,
    required String content,
    bool isHost = false,
  }) async {
    if (_apiClient != null) {
      try {
        final payload = await _apiClient!.postJsonAny(
          '/events/$eventId/chat/messages',
          {
            'userId': userId,
            'userName': userName,
            'userAvatarUrl': userAvatarUrl,
            'content': content,
            'isHost': isHost,
            'schemaVersion': APIConfig.getBackendApiVersion(),
          },
        );
        final raw = payload is Map<String, dynamic>
            ? (payload['item'] is Map<String, dynamic>
                ? Map<String, dynamic>.from(payload['item'] as Map)
                : payload)
            : <String, dynamic>{};
        if (raw.isNotEmpty) {
          final message = MeetupChatMessage.fromJson(raw);
          _upsertMessage(eventId, message);
          return message;
        }
      } catch (_) {
        // fallback below
      }
    }

    await Future.delayed(const Duration(milliseconds: 400));
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
    _upsertMessage(eventId, message);
    return message;
  }

  Future<bool> deleteMessage(String eventId, String messageId) async {
    if (_apiClient != null) {
      try {
        await _apiClient!.delete('/events/$eventId/chat/messages/$messageId');
        _chatMessages[eventId]?.removeWhere((m) => m.id == messageId);
        return true;
      } catch (_) {
        // fallback below
      }
    }

    await Future.delayed(const Duration(milliseconds: 300));
    if (_chatMessages.containsKey(eventId)) {
      final originalLength = _chatMessages[eventId]!.length;
      _chatMessages[eventId]!.removeWhere((m) => m.id == messageId);
      return _chatMessages[eventId]!.length < originalLength;
    }
    return false;
  }

  Future<MeetupChatReport> reportMessage({
    required String eventId,
    required String reportedMessageId,
    required String reporterId,
    required String reason,
    String? description,
  }) async {
    if (_apiClient != null) {
      try {
        final payload = await _apiClient!.postJsonAny(
          '/events/$eventId/chat/reports',
          {
            'reportedMessageId': reportedMessageId,
            'reporterId': reporterId,
            'reason': reason,
            'description': description,
            'schemaVersion': APIConfig.getBackendApiVersion(),
          },
        );
        final raw = payload is Map<String, dynamic>
            ? (payload['item'] is Map<String, dynamic>
                ? Map<String, dynamic>.from(payload['item'] as Map)
                : payload)
            : <String, dynamic>{};
        if (raw.isNotEmpty) {
          final report = MeetupChatReport.fromJson(raw);
          _upsertReport(report);
          return report;
        }
      } catch (_) {
        // fallback below
      }
    }

    await Future.delayed(const Duration(milliseconds: 500));
    final report = MeetupChatReport(
      id: 'report_${DateTime.now().millisecondsSinceEpoch}',
      reportedMessageId: reportedMessageId,
      reporterId: reporterId,
      reason: reason,
      description: description,
      reportedAt: DateTime.now(),
    );
    _upsertReport(report);
    return report;
  }

  Future<List<MeetupChatReport>> getAllReports() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.from(_reports);
  }

  Future<List<MeetupChatReport>> getReportsForEvent(String eventId) async {
    if (_apiClient != null) {
      try {
        final payload = await _apiClient!.getJson('/events/$eventId/chat/reports');
        if (payload is Map<String, dynamic> && payload['items'] is List) {
          final items = (payload['items'] as List)
              .whereType<Map>()
              .map((item) => MeetupChatReport.fromJson(Map<String, dynamic>.from(item)))
              .toList();
          for (final report in items) {
            _upsertReport(report);
          }
          return items;
        }
      } catch (_) {
        // fallback below
      }
    }

    await Future.delayed(const Duration(milliseconds: 300));
    final eventMessages = _chatMessages[eventId] ?? [];
    final eventMessageIds = eventMessages.map((m) => m.id).toSet();
    return _reports
        .where((report) => eventMessageIds.contains(report.reportedMessageId))
        .toList();
  }

  Future<bool> hasAccessToChat({
    required String eventId,
    required String userId,
    required String? hosterId,
  }) async {
    if (_apiClient != null) {
      try {
        final payload = await _apiClient!.getJson(
          '/events/$eventId/chat/access?userId=$userId&hosterId=${hosterId ?? ''}',
        );
        if (payload is Map<String, dynamic>) {
          return payload['hasAccess'] as bool? ?? false;
        }
      } catch (_) {
        // fallback below
      }
    }

    return userId == hosterId;
  }
}