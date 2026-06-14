enum EventInvitationStatus { pending, accepted, declined }

class EventInvitation {
  final String id;
  final String eventId;
  final String hostUserId;
  final String invitedUserId;
  final DateTime createdAt;
  final EventInvitationStatus status;

  const EventInvitation({
    required this.id,
    required this.eventId,
    required this.hostUserId,
    required this.invitedUserId,
    required this.createdAt,
    this.status = EventInvitationStatus.pending,
  });

  factory EventInvitation.fromJson(Map<String, dynamic> json) {
    final rawStatus = (json['status'] ?? 'pending').toString();
    final status = EventInvitationStatus.values.firstWhere(
      (value) => value.name == rawStatus,
      orElse: () => EventInvitationStatus.pending,
    );

    return EventInvitation(
      id: (json['id'] ?? '').toString(),
      eventId: (json['eventId'] ?? json['event_id'] ?? '').toString(),
      hostUserId:
          (json['hostUserId'] ?? json['host_user_id'] ?? '').toString(),
      invitedUserId:
          (json['invitedUserId'] ?? json['invited_user_id'] ?? '').toString(),
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      status: status,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'eventId': eventId,
      'hostUserId': hostUserId,
      'invitedUserId': invitedUserId,
      'createdAt': createdAt.toIso8601String(),
      'status': status.name,
    };
  }
}
