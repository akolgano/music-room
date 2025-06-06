// lib/providers/device_provider.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/models.dart';

class DeviceProvider with ChangeNotifier {
  final ApiService _api = ApiService();
  
  Device? _currentDevice;
  List<Device> _userDevices = [];
  bool _isLoading = false;
  String? _errorMessage;

  Device? get currentDevice => _currentDevice;
  List<Device> get userDevices => List.unmodifiable(_userDevices);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;
  String? get deviceUuid => _currentDevice?.uuid;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<T?> _execute<T>(Future<T> Function() operation) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await operation();
      return result;
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> initializeDevice(String token) async {
    await _execute(() async {
      await fetchUserDevices(token);
      
      if (_userDevices.isEmpty) {
        await _registerCurrentDevice(token);
      } else {
        _currentDevice = _userDevices.firstWhere(
          (device) => device.isActive,
          orElse: () => _userDevices.first,
        );
      }
    });
  }

  Future<void> _registerCurrentDevice(String token) async {
    final deviceName = 'Mobile App ${DateTime.now().millisecondsSinceEpoch}';
    final uuid = 'mobile-${DateTime.now().millisecondsSinceEpoch}';
    final licenseKey = _generateLicenseKey();

    final device = await _api.registerDevice(uuid, licenseKey, deviceName, token);
    if (device != null) {
      _currentDevice = device;
      _userDevices.add(device);
      notifyListeners();
    }
  }

  Future<void> fetchUserDevices(String token) async {
    final result = await _execute(() => _api.getUserDevices(token));
    if (result != null) _userDevices = result;
  }

  Future<Device?> registerDevice(String uuid, String licenseKey, String deviceName, String token) async {
    final result = await _execute(() async {
      final device = await _api.registerDevice(uuid, licenseKey, deviceName, token);
      if (device != null) {
        _userDevices.add(device);
        if (_currentDevice == null) {
          _currentDevice = device;
        }
      }
      return device;
    });
    return result;
  }

  Future<bool> checkControlPermission(String deviceUuid, String token) async {
    final result = await _execute(() => _api.checkControlPermission(deviceUuid, token));
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
