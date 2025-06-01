// lib/models/device.dart
class Device {
  final String id;
  final String uuid;
  final String name;
  final bool isActive;
  final String licenseKey;
  final DateTime createdAt;
  
  Device({
    required this.id,
    required this.uuid,
    required this.name,
    required this.isActive,
    required this.licenseKey,
    required this.createdAt,
  });
  
  factory Device.fromJson(Map<String, dynamic> json) => Device(
    id: json['id'].toString(),
    uuid: json['uuid'] ?? '',
    name: json['device_name'] ?? json['name'] ?? '',
    isActive: json['is_active'] ?? json['active'] ?? false,
    licenseKey: json['license_key'] ?? '',
    createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
  );
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'uuid': uuid,
    'device_name': name,
    'is_active': isActive,
    'license_key': licenseKey,
    'created_at': createdAt.toIso8601String(),
  };
}
