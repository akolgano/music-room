import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class LocationException implements Exception {
  final String message;
  LocationException(this.message);
  @override
  String toString() => message;
}

class LocationService {
  static const String _geonamesUsername = 'demo';
  static const String _geonamesBaseUrl = 'http://api.geonames.org';
  static const String _ipApiUrl = 'http://ip-api.com/json';
  
  static Future<List<LocationSuggestion>> searchCities(String query) async {
    if (query.trim().isEmpty || query.length < 2) return [];
    try {
      final response = await http.get(Uri.parse(
        '$_geonamesBaseUrl/searchJSON?name_startsWith=${Uri.encodeComponent(query.trim())}&maxRows=10&featureClass=P&username=$_geonamesUsername'
      )).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['geonames'] != null) {
          return (data['geonames'] as List).map((item) => LocationSuggestion.fromGeonames(item)).take(10).toList();
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error fetching location suggestions: $e');
    }
    return [];
  }

  static Future<LocationSuggestion?> getLocationByIP() async {
    try {
      final response = await http.get(Uri.parse(_ipApiUrl)).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          return LocationSuggestion(
            name: data['city'] as String,
            country: data['country'] as String,
            adminName: data['regionName'] as String?,
          );
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error getting location by IP: $e');
    }
    return null;
  }

  static Future<LocationSuggestion?> getCurrentLocation() async {
    final gpsLocation = await _tryGpsLocation();
    if (gpsLocation != null) return gpsLocation;
    try {
      final ipLocation = await getLocationByIP();
      if (ipLocation != null) {
        if (kDebugMode) debugPrint('Location detected via IP: ${ipLocation.displayName}');
        return ipLocation;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('IP location also failed: $e');
    }
    throw LocationException('Unable to detect location automatically.${kIsWeb ? ' GPS requires HTTPS and location permissions. Tried IP-based detection as backup.' : ''}');
  }

  static Future<LocationSuggestion?> _tryGpsLocation() async {
    try {
      final position = await _getGpsPosition();
      return position != null ? await _reverseGeocode(position.latitude, position.longitude) : null;
    } catch (e) {
      if (kDebugMode) debugPrint('GPS location failed, trying IP fallback: $e');
      return null;
    }
  }

  static Future<Position?> _getGpsPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) return null;
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
    return (permission == LocationPermission.whileInUse || permission == LocationPermission.always)
      ? await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium, timeLimit: Duration(seconds: 15)))
      : null;
  }

  static Future<LocationSuggestion?> _reverseGeocode(double latitude, double longitude) async {
    try {
      final response = await http.get(Uri.parse(
        '$_geonamesBaseUrl/findNearbyPlaceNameJSON?lat=$latitude&lng=$longitude&username=$_geonamesUsername'
      )).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['geonames'] != null && (data['geonames'] as List).isNotEmpty) {
          final place = (data['geonames'] as List).first;
          return LocationSuggestion(
            name: place['name'] as String,
            country: place['countryName'] as String,
            adminName: place['adminName1'] as String?,
          );
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error reverse geocoding: $e');
    }
    return null;
  }
}

class LocationSuggestion {
  final String name;
  final String country;
  final String? adminName;
  
  LocationSuggestion({required this.name, required this.country, this.adminName});
  
  factory LocationSuggestion.fromGeonames(Map<String, dynamic> json) => LocationSuggestion(
    name: json['name'] as String,
    country: json['countryName'] as String,
    adminName: json['adminName1'] as String?,
  );
  
  String get displayName => (adminName != null && adminName!.isNotEmpty && adminName != name)
    ? '$name, $adminName, $country' : '$name, $country';
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocationSuggestion &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          country == other.country &&
          adminName == other.adminName;

  @override
  int get hashCode => Object.hash(name, country, adminName);
}