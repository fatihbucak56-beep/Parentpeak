import 'package:flutter_test/flutter_test.dart';
import 'package:trusted_circle_demo/models/trusted_device.dart';

void main() {
  test('import works', () {
    final d = TrustedDevice(deviceUuid: 'x', deviceName: 'n', status: DeviceStatus.active);
    expect(d.deviceName, 'n');
  });
}
