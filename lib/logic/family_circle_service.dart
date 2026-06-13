import 'package:trusted_circle_demo/models/family_contact.dart';

class FamilyCircleService {
  FamilyCircleService._();

  static final FamilyCircleService instance = FamilyCircleService._();

  static final List<FamilyContact> _contacts = [
    const FamilyContact(
      userId: 'host_001',
      displayName: 'Mia Schneider',
      city: 'Berlin',
      childrenSummary: 'Kind: 4 Jahre',
    ),
    const FamilyContact(
      userId: 'host_002',
      displayName: 'Lena Yilmaz',
      city: 'Berlin',
      childrenSummary: 'Kinder: 7 und 10 Jahre',
    ),
    const FamilyContact(
      userId: 'host_003',
      displayName: 'Noah Weber',
      city: 'Berlin',
      childrenSummary: 'Kind: 2 Jahre',
    ),
    const FamilyContact(
      userId: 'host_demo_001',
      displayName: 'Du',
      city: 'Berlin',
      childrenSummary: 'Familienprofil',
    ),
  ];

  static final Set<String> _connectionKeys = {
    _pairKey('host_demo_001', 'host_001'),
    _pairKey('host_demo_001', 'host_002'),
  };

  static final List<FamilyConnectionRequest> _incomingRequests = [
    FamilyConnectionRequest(
      id: 'req_1',
      fromUserId: 'host_003',
      toUserId: 'host_demo_001',
      fromDisplayName: 'Noah Weber',
      sentAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  static String _pairKey(String a, String b) {
    final sorted = [a, b]..sort();
    return '${sorted[0]}::${sorted[1]}';
  }

  Future<List<FamilyContact>> getConnectedContacts({required String userId}) async {
    await Future.delayed(const Duration(milliseconds: 180));
    return _contacts.where((c) {
      if (c.userId == userId) return false;
      return areUsersConnected(userA: userId, userB: c.userId);
    }).toList();
  }

  Future<List<FamilyConnectionRequest>> getIncomingRequests({
    required String userId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 180));
    return _incomingRequests
        .where((r) => r.toUserId == userId && r.status == FamilyRequestStatus.pending)
        .toList();
  }

  Future<void> respondToRequest({
    required String requestId,
    required bool accept,
  }) async {
    await Future.delayed(const Duration(milliseconds: 180));

    final index = _incomingRequests.indexWhere((r) => r.id == requestId);
    if (index == -1) return;

    final req = _incomingRequests[index];
    _incomingRequests[index] = FamilyConnectionRequest(
      id: req.id,
      fromUserId: req.fromUserId,
      toUserId: req.toUserId,
      fromDisplayName: req.fromDisplayName,
      sentAt: req.sentAt,
      status: accept ? FamilyRequestStatus.accepted : FamilyRequestStatus.declined,
    );

    if (accept) {
      _connectionKeys.add(_pairKey(req.fromUserId, req.toUserId));
    }
  }

  bool areUsersConnected({required String userA, required String userB}) {
    return _connectionKeys.contains(_pairKey(userA, userB));
  }

  FamilyContact? getContactByUserId(String userId) {
    for (final c in _contacts) {
      if (c.userId == userId) return c;
    }
    return null;
  }
}
