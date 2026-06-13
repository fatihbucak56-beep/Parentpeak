enum FamilyRequestStatus { pending, accepted, declined }

class FamilyContact {
  final String userId;
  final String displayName;
  final String city;
  final String childrenSummary;

  const FamilyContact({
    required this.userId,
    required this.displayName,
    required this.city,
    required this.childrenSummary,
  });
}

class FamilyConnectionRequest {
  final String id;
  final String fromUserId;
  final String toUserId;
  final String fromDisplayName;
  final DateTime sentAt;
  final FamilyRequestStatus status;

  const FamilyConnectionRequest({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.fromDisplayName,
    required this.sentAt,
    this.status = FamilyRequestStatus.pending,
  });
}
