class MeetupChatMessage {
  final String id;
  final String eventId;
  final String userId;
  final String userName;
  final String userAvatarUrl;
  final String content;
  final DateTime timestamp;
  final bool isHost;

  MeetupChatMessage({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.userName,
    required this.userAvatarUrl,
    required this.content,
    required this.timestamp,
    this.isHost = false,
  });

  factory MeetupChatMessage.fromJson(Map<String, dynamic> json) =>
      MeetupChatMessage(
        id: json['id'] as String,
        eventId: json['eventId'] as String,
        userId: json['userId'] as String,
        userName: json['userName'] as String,
        userAvatarUrl: json['userAvatarUrl'] as String,
        content: json['content'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        isHost: json['isHost'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'eventId': eventId,
        'userId': userId,
        'userName': userName,
        'userAvatarUrl': userAvatarUrl,
        'content': content,
        'timestamp': timestamp.toIso8601String(),
        'isHost': isHost,
      };
}

class MeetupChatReport {
  final String id;
  final String reportedMessageId;
  final String reporterId;
  final String reason;
  final String? description;
  final DateTime reportedAt;

  MeetupChatReport({
    required this.id,
    required this.reportedMessageId,
    required this.reporterId,
    required this.reason,
    this.description,
    required this.reportedAt,
  });

  factory MeetupChatReport.fromJson(Map<String, dynamic> json) =>
      MeetupChatReport(
        id: json['id'] as String,
        reportedMessageId: json['reportedMessageId'] as String,
        reporterId: json['reporterId'] as String,
        reason: json['reason'] as String,
        description: json['description'] as String?,
        reportedAt: DateTime.parse(json['reportedAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'reportedMessageId': reportedMessageId,
        'reporterId': reporterId,
        'reason': reason,
        'description': description,
        'reportedAt': reportedAt.toIso8601String(),
      };
}
