import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dieses Gerät kann nicht entfernt werden.')));
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gerät erfolgreich entfernt.')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fehler beim Entfernen des Geräts.')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Fehler: $e')));
    } finally {
      setState(() => _busy.remove(device.deviceUuid));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vertrauenswürdige Geräte')),
      body: ListView.builder(
        itemCount: _devices.length,
        itemBuilder: (context, index) {
          final device = _devices[index];
          final isRevoked = device.status == DeviceStatus.revoked;
          return ListTile(
            key: Key(device.deviceUuid),
            leading: Icon(isRevoked ? Icons.lock_outline : Icons.check_circle_outline, color: isRevoked ? Theme.of(context).colorScheme.error : Colors.green),
            title: Text(device.deviceName, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: isRevoked && device.revokedAt != null ? Text('Entfernt am: ${_formatDate(context, device.revokedAt!)}') : null,
            trailing: isRevoked
                ? null
                : _busy.contains(device.deviceUuid)
                    ? const SizedBox(width: 88, height: 36, child: Center(child: CircularProgressIndicator()))
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                        child: const Text('Gerät entfernen'),
                        onPressed: () => _confirmAndRevoke(device),
                      ),
          );
        },
      ),
    );
  }
}
