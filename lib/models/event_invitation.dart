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
}
