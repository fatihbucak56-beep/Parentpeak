import 'package:trusted_circle_demo/config/api_config.dart';
import 'package:trusted_circle_demo/logic/backend_service_factory.dart';
import 'package:trusted_circle_demo/models/family_contact.dart';

class FamilyCircleService {
  FamilyCircleService._();

  static final FamilyCircleService instance = FamilyCircleService._();
  static final _apiClient = BackendServiceFactory.createApiClient();

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

  List<FamilyContact> _localContactsFor(String userId) {
    return [
      ..._contacts.where((contact) => contact.userId != 'host_demo_001'),
      FamilyContact(
        userId: userId,
        displayName: 'Du',
        city: 'Berlin',
        childrenSummary: 'Familienprofil',
      ),
    ];
  }

  Set<String> _localConnectionKeysFor(String userId) {
    return {
      _pairKey(userId, 'host_001'),
      _pairKey(userId, 'host_002'),
      ..._connectionKeys.where((key) => !key.contains('host_demo_001')),
    };
  }

  List<FamilyConnectionRequest> _localRequestsFor(String userId) {
    return [
      FamilyConnectionRequest(
        id: 'req_1',
        fromUserId: 'host_003',
        toUserId: userId,
        fromDisplayName: 'Noah Weber',
        sentAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];
  }

  Future<List<FamilyContact>> getConnectedContacts({required String userId}) async {
    if (_apiClient != null) {
      try {
        final payload = await _apiClient!
            .getJson('${APIConfig.getBackendFamilyContactsPath()}?userId=$userId');
        final remote = _parseContacts(payload);
        if (remote.isNotEmpty) return remote;
      } catch (_) {
        // Fallback below.
      }
    }

    await Future.delayed(const Duration(milliseconds: 180));
    final contacts = _localContactsFor(userId);
    final connectionKeys = _localConnectionKeysFor(userId);
    return contacts.where((c) {
      if (c.userId == userId) return false;
      return connectionKeys.contains(_pairKey(userId, c.userId));
    }).toList();
  }

  Future<List<FamilyConnectionRequest>> getIncomingRequests({
    required String userId,
  }) async {
    if (_apiClient != null) {
      try {
        final payload = await _apiClient!
            .getJson('${APIConfig.getBackendFamilyRequestsPath()}?userId=$userId');
        final remote = _parseRequests(payload);
        if (remote.isNotEmpty) {
          return remote
              .where((r) =>
                  r.toUserId == userId && r.status == FamilyRequestStatus.pending)
              .toList();
        }
      } catch (_) {
        // Fallback below.
      }
    }

    await Future.delayed(const Duration(milliseconds: 180));
    return _localRequestsFor(userId)
        .where((r) => r.toUserId == userId && r.status == FamilyRequestStatus.pending)
        .toList();
  }

  Future<void> respondToRequest({
    required String requestId,
    required bool accept,
    String? actingUserId,
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

    if (_apiClient != null) {
      try {
        final path = APIConfig.getBackendFamilyRequestsPath();
        final normalizedPath = path.endsWith('/')
            ? '${path.substring(0, path.length - 1)}/$requestId'
            : '$path/$requestId';
        await _apiClient!.putJson(
          normalizedPath,
          {
            'status': accept ? 'accepted' : 'declined',
            if (actingUserId != null) 'actingUserId': actingUserId,
            'updatedAt': DateTime.now().toUtc().toIso8601String(),
            'schemaVersion': APIConfig.getBackendApiVersion(),
          },
        );
      } catch (_) {
        // Local state remains source of truth if backend update fails.
      }
    }
  }

  /// Sends a new connection request to [toUserId] from [fromUserId].
  /// [actingUserId] must equal [fromUserId] to pass the backend security guard.
  Future<FamilyConnectionRequest?> sendRequest({
    required String fromUserId,
    required String toUserId,
    String? fromDisplayName,
  }) async {
    // Optimistically add to local state.
    final localReq = FamilyConnectionRequest(
      id: 'req_local_${DateTime.now().microsecondsSinceEpoch}',
      fromUserId: fromUserId,
      toUserId: toUserId,
      fromDisplayName: fromDisplayName ?? fromUserId,
      sentAt: DateTime.now(),
    );
    _incomingRequests.add(localReq);

    if (_apiClient != null) {
      try {
        final payload = await _apiClient!.postJson(
          APIConfig.getBackendFamilyRequestsPath(),
          {
            'fromUserId': fromUserId,
            'toUserId': toUserId,
            'actingUserId': fromUserId,
            'status': 'pending',
            'schemaVersion': APIConfig.getBackendApiVersion(),
          },
        );
        final raw = payload['item'] is Map<String, dynamic>
            ? Map<String, dynamic>.from(payload['item'] as Map)
            : payload;
        if ((raw['id'] ?? '').toString().isNotEmpty) {
          // Replace the optimistic entry with the server-issued one.
          final idx = _incomingRequests.indexWhere((r) => r.id == localReq.id);
          final serverReq = FamilyConnectionRequest(
            id: raw['id'].toString(),
            fromUserId: fromUserId,
            toUserId: toUserId,
            fromDisplayName: fromDisplayName ?? fromUserId,
            sentAt: DateTime.tryParse((raw['createdAt'] ?? '').toString()) ??
                DateTime.now(),
          );
          if (idx != -1) {
            _incomingRequests[idx] = serverReq;
          }
          return serverReq;
        }
      } catch (_) {
        // Local optimistic entry stays.
      }
    }
    return localReq;
  }

  /// Removes a family connection request by [requestId].
  /// [actingUserId] is forwarded to the backend security guard.
  Future<void> deleteRequest({
    required String requestId,
    String? actingUserId,
  }) async {
    _incomingRequests.removeWhere((r) => r.id == requestId);

    if (_apiClient != null) {
      try {
        final basePath = APIConfig.getBackendFamilyRequestsPath();
        final normalizedPath = basePath.endsWith('/')
            ? '${basePath.substring(0, basePath.length - 1)}/$requestId'
            : '$basePath/$requestId';
        final queryParam = actingUserId != null
            ? '?actingUserId=${Uri.encodeComponent(actingUserId)}'
            : '';
        await _apiClient!.delete('$normalizedPath$queryParam');
      } catch (_) {
        // Local deletion already applied.
      }
    }
  }

  /// Deletes an accepted relationship between two users by resolving its
  /// backend request ID first, then calling [deleteRequest].
  Future<bool> deleteConnectionWithUser({
    required String currentUserId,
    required String otherUserId,
  }) async {
    _connectionKeys.remove(_pairKey(currentUserId, otherUserId));

    if (_apiClient != null) {
      try {
        final path = APIConfig.getBackendFamilyRequestsPath();
        final qA =
            '?fromUserId=${Uri.encodeComponent(currentUserId)}&toUserId=${Uri.encodeComponent(otherUserId)}&status=accepted';
        final qB =
            '?fromUserId=${Uri.encodeComponent(otherUserId)}&toUserId=${Uri.encodeComponent(currentUserId)}&status=accepted';

        final resA = await _apiClient!.getJson('$path$qA');
        final resB = await _apiClient!.getJson('$path$qB');
        final candidates = [
          ..._parseRequests(resA),
          ..._parseRequests(resB),
        ];

        for (final req in candidates) {
          final isPair = (req.fromUserId == currentUserId && req.toUserId == otherUserId) ||
              (req.fromUserId == otherUserId && req.toUserId == currentUserId);
          if (!isPair) continue;

          await deleteRequest(
            requestId: req.id,
            actingUserId: currentUserId,
          );
          return true;
        }
      } catch (_) {
        // Fall through to local fallback below.
      }
    }

    _incomingRequests.removeWhere((r) {
      final isPair = (r.fromUserId == currentUserId && r.toUserId == otherUserId) ||
          (r.fromUserId == otherUserId && r.toUserId == currentUserId);
      return isPair;
    });
    return true;
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

  static List<FamilyContact> _parseContacts(dynamic payload) {
    final rawList = <Map<String, dynamic>>[];

    if (payload is List) {
      for (final item in payload) {
        if (item is Map) rawList.add(Map<String, dynamic>.from(item));
      }
    } else if (payload is Map) {
      final map = Map<String, dynamic>.from(payload);
      final list = map['contacts'] ?? map['items'] ?? map['data'] ?? map['results'];
      if (list is List) {
        for (final item in list) {
          if (item is Map) rawList.add(Map<String, dynamic>.from(item));
        }
      }
    }

    return rawList
        .map(
          (raw) => FamilyContact(
            userId: (raw['userId'] ?? raw['id'] ?? '').toString(),
            displayName: (raw['displayName'] ?? raw['name'] ?? 'Kontakt').toString(),
            city: (raw['city'] ?? '').toString(),
            childrenSummary: (raw['childrenSummary'] ?? raw['children'] ?? '').toString(),
          ),
        )
        .where((c) => c.userId.isNotEmpty)
        .toList();
  }

  static List<FamilyConnectionRequest> _parseRequests(dynamic payload) {
    final rawList = <Map<String, dynamic>>[];

    if (payload is List) {
      for (final item in payload) {
        if (item is Map) rawList.add(Map<String, dynamic>.from(item));
      }
    } else if (payload is Map) {
      final map = Map<String, dynamic>.from(payload);
      final list = map['requests'] ?? map['items'] ?? map['data'] ?? map['results'];
      if (list is List) {
        for (final item in list) {
          if (item is Map) rawList.add(Map<String, dynamic>.from(item));
        }
      }
    }

    FamilyRequestStatus parseStatus(String raw) {
      switch (raw.toLowerCase().trim()) {
        case 'accepted':
          return FamilyRequestStatus.accepted;
        case 'declined':
          return FamilyRequestStatus.declined;
        default:
          return FamilyRequestStatus.pending;
      }
    }

    return rawList
        .map(
          (raw) => FamilyConnectionRequest(
            id: (raw['id'] ?? raw['_id'] ?? '').toString(),
            fromUserId: (raw['fromUserId'] ?? raw['from'] ?? '').toString(),
            toUserId: (raw['toUserId'] ?? raw['to'] ?? '').toString(),
            fromDisplayName:
                (raw['fromDisplayName'] ?? raw['fromName'] ?? 'Unbekannt').toString(),
            sentAt: DateTime.tryParse((raw['sentAt'] ?? '').toString()) ?? DateTime.now(),
            status: parseStatus((raw['status'] ?? 'pending').toString()),
          ),
        )
        .where((r) => r.id.isNotEmpty)
        .toList();
  }
}
