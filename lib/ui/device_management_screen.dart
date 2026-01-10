import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:trusted_circle_demo/l10n/app_localizations.dart';
import '../models/trusted_device.dart';
import 'revoke_confirmation_dialog.dart';

class DeviceManagementScreen extends StatefulWidget {
  final List<TrustedDevice> devices;
  final Future<bool> Function(String deviceUuid, String deviceName) onRevoke;

  const DeviceManagementScreen({Key? key, required this.devices, required this.onRevoke}) : super(key: key);

  @override
  State<DeviceManagementScreen> createState() => _DeviceManagementScreenState();
}

class _DeviceManagementScreenState extends State<DeviceManagementScreen> {
  late List<TrustedDevice> _devices;
  final Set<String> _busy = {};

  @override
  void initState() {
    super.initState();
    _devices = widget.devices.map((d) => d).toList();
  }

  String _formatDate(BuildContext ctx, DateTime date) {
    return DateFormat.yMMMd(Localizations.localeOf(ctx).toString()).add_Hm().format(date);
  }

  Future<void> _confirmAndRevoke(TrustedDevice device) async {
    if (device.isPriorityApprover) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.cannotRemovePriority)));
      return;
    }

    final confirmed = await showDialog<bool>(context: context, builder: (_) => RevokeConfirmationDialog(deviceName: device.deviceName));
    if (confirmed != true) return;

    setState(() => _busy.add(device.deviceUuid));
    try {
      final ok = await widget.onRevoke(device.deviceUuid, device.deviceName);
      if (ok) {
        setState(() {
          final idx = _devices.indexWhere((d) => d.deviceUuid == device.deviceUuid);
          if (idx != -1) {
            _devices[idx] = TrustedDevice(
              deviceUuid: device.deviceUuid,
              deviceName: device.deviceName,
              status: DeviceStatus.revoked,
              revokedAt: DateTime.now(),
              isPriorityApprover: device.isPriorityApprover,
            );
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.deviceRemoved)));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.deviceRemoveError)));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Fehler: $e')));
    } finally {
      setState(() => _busy.remove(device.deviceUuid));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _devices.length,
        itemBuilder: (context, index) {
          final device = _devices[index];
          final isRevoked = device.status == DeviceStatus.revoked;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Card(
              key: Key(device.deviceUuid),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey[200]!, width: 1),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isRevoked 
                          ? theme.colorScheme.errorContainer 
                          : theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isRevoked ? Icons.block_rounded : Icons.phone_android_rounded,
                        color: isRevoked ? theme.colorScheme.error : theme.colorScheme.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  device.deviceName,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isRevoked 
                                    ? theme.colorScheme.errorContainer 
                                    : Colors.green[50],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isRevoked ? Icons.block : Icons.check_circle,
                                      size: 12,
                                      color: isRevoked ? theme.colorScheme.error : Colors.green[700],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      isRevoked ? 'Entfernt' : 'Aktiv',
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        color: isRevoked ? theme.colorScheme.error : Colors.green[700],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (isRevoked && device.revokedAt != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              AppLocalizations.of(context)!.removedAt(_formatDate(context, device.revokedAt!)),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                          if (!isRevoked) ...[
                            const SizedBox(height: 8),
                            if (_busy.contains(device.deviceUuid))
                              const SizedBox(
                                height: 32,
                                child: Center(child: CircularProgressIndicator()),
                              )
                            else
                              FilledButton.tonal(
                                key: Key('revoke-${device.deviceUuid}'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: theme.colorScheme.errorContainer,
                                  foregroundColor: theme.colorScheme.error,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                ),
                                onPressed: () => _confirmAndRevoke(device),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.delete_outline, size: 16),
                                    const SizedBox(width: 8),
                                    Text(AppLocalizations.of(context)!.removeDevice),
                                  ],
                                ),
                              ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
