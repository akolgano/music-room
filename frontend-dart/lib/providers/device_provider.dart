// lib/providers/device_provider.dart
import 'package:flutter/material.dart';
import '../core/service_locator.dart';
import '../core/base_provider.dart';  
import '../services/device_service.dart';
import '../models/models.dart';

class DeviceProvider extends BaseProvider {  
  final DeviceService _deviceService = getIt<DeviceService>();
  Device? _currentDevice;
  List<Device> _userDevices = [];

  Device? get currentDevice => _currentDevice;
  List<Device> get userDevices => List.unmodifiable(_userDevices);
  String? get deviceUuid => _currentDevice?.uuid;

  Future<void> initializeDevice(String token) async {
    await executeAsync(
      () async {
        await fetchUserDevices(token);
        if (_userDevices.isEmpty) {
          await _registerCurrentDevice(token);
        } else {
          _currentDevice = _userDevices.firstWhere((device) => device.isActive, orElse: () => _userDevices.first);
        }
      },
      errorMessage: 'Failed to initialize device setup',
    );
  }

  Future<void> _registerCurrentDevice(String token) async {
    final deviceName = 'Mobile App ${DateTime.now().millisecondsSinceEpoch}';
    final uuid = 'mobile-${DateTime.now().millisecondsSinceEpoch}';
    final licenseKey = _generateLicenseKey();

    final device = await executeAsync(
      () => _deviceService.registerDevice(uuid, licenseKey, deviceName, token),
      errorMessage: 'Failed to register default device',
    );

    if (device != null) {
      _currentDevice = device;
      _userDevices.add(device);
      notifyListeners();
    }
  }

  Future<void> fetchUserDevices(String token) async {
    final result = await executeAsync(
      () => _deviceService.getUserDevices(token),
      errorMessage: 'Failed to load your devices',
    );
    if (result != null) _userDevices = result;
  }

  Future<Device?> registerDevice(String uuid, String licenseKey, String deviceName, String token) async {
    return executeAsync(
      () async {
        final device = await _deviceService.registerDevice(uuid, licenseKey, deviceName, token);
        _userDevices.add(device);
        if (_currentDevice == null) {
          _currentDevice = device;
        }
        notifyListeners();
        return device;
      },
      successMessage: 'Device "$deviceName" registered successfully',
      errorMessage: 'Failed to register device "$deviceName"',
    );
  }

  Future<bool> checkControlPermission(String deviceUuid, String token) async {
    final result = await executeAsync(
      () => _deviceService.checkControlPermission(deviceUuid, token),
      errorMessage: 'Failed to check device permissions',
    );
    return result ?? false;
  }

  void setCurrentDevice(Device device) {
    _currentDevice = device;
    notifyListeners();
  }

  String _generateLicenseKey() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(16, (index) => chars[(DateTime.now().millisecondsSinceEpoch + index) % chars.length]).join();
  }
}
