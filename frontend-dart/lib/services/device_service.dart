// lib/services/device_service.dart
import '../services/api_service.dart';
import '../models/models.dart';
import '../models/api_models.dart';

class DeviceService {
  final ApiService _api;
  DeviceService(this._api);

  Future<List<Device>> getUserDevices(String token) async {
    final response = await _api.getUserDevices(token); 
    return response.devices;
  }

  Future<List<Device>> getAllUserDevices(String token) async {
    final response = await _api.getAllUserDevices(token); 
    return response.devices;
  }

  Future<Device> registerDevice(String uuid, String licenseKey, String deviceName, String token) async {
    final request = RegisterDeviceRequest(uuid: uuid, licenseKey: licenseKey, deviceName: deviceName);
    final response = await _api.registerDevice(token, request); 
    return response.device;
  }

  Future<bool> checkControlPermission(String deviceUuid, String token) async {
    final response = await _api.checkControlPermission(deviceUuid, token); 
    return response.canControl;
  }

  Future<void> delegateDeviceControl({required String deviceUuid, required int delegateUserId, required bool canControl, required String token}) async {
    final request = DelegateControlRequest(deviceUuid: deviceUuid, delegateUserId: delegateUserId, canControl: canControl);
    await _api.delegateDeviceControl(token, request);
  }
}
