enum DeviceStatus { active, revoked }

class TrustedDevice {
  final String deviceUuid;
  final String deviceName;
  final DeviceStatus status;
  final DateTime? revokedAt;
  final bool isPriorityApprover;

  TrustedDevice({
    required this.deviceUuid,
    required this.deviceName,
    required this.status,
    this.revokedAt,
    this.isPriorityApprover = false,
  });

  bool get isRevoked => status == DeviceStatus.revoked;

  factory TrustedDevice.fromJson(Map<String, dynamic> json) => TrustedDevice(
        deviceUuid: json['deviceUuid'] as String,
        deviceName: json['deviceName'] as String,
        status: (json['status'] as String) == 'REVOKED' ? DeviceStatus.revoked : DeviceStatus.active,
        revokedAt: json['revokedAt'] != null ? DateTime.parse(json['revokedAt'] as String) : null,
        isPriorityApprover: json['isPriorityApprover'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'deviceUuid': deviceUuid,
        'deviceName': deviceName,
        'status': status == DeviceStatus.revoked ? 'REVOKED' : 'ACTIVE',
        'revokedAt': revokedAt?.toIso8601String(),
        'isPriorityApprover': isPriorityApprover,
      };
}
