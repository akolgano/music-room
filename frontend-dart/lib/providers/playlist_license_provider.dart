// lib/providers/playlist_license_provider.dart
import 'package:flutter/material.dart';

class PlaylistLicenseProvider with ChangeNotifier {
  bool _canCurrentUserEdit = true;
  bool _isLicenseValid = true;
  String? _licenseType;
  Map<String, bool> _userPermissions = {};

  bool get canCurrentUserEdit => _canCurrentUserEdit;
  bool get isLicenseValid => _isLicenseValid;
  String? get licenseType => _licenseType;
  Map<String, bool> get userPermissions => Map.unmodifiable(_userPermissions);

  void setCanEdit(bool canEdit) {
    _canCurrentUserEdit = canEdit;
    notifyListeners();
  }

  void setLicenseValidity(bool isValid) {
    _isLicenseValid = isValid;
    notifyListeners();
  }

  void setLicenseType(String? type) {
    _licenseType = type;
    notifyListeners();
  }

  void updateUserPermissions(Map<String, bool> permissions) {
    _userPermissions = Map.from(permissions);
    notifyListeners();
  }

  void setUserPermission(String userId, bool hasPermission) {
    _userPermissions[userId] = hasPermission;
    notifyListeners();
  }

  bool getUserPermission(String userId) {
    return _userPermissions[userId] ?? false;
  }

  void reset() {
    _canCurrentUserEdit = true;
    _isLicenseValid = true;
    _licenseType = null;
    _userPermissions.clear();
    notifyListeners();
  }
}
