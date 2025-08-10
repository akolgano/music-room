import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  static const String _geonamesUsername = 'demo';
  static const String _geonamesBaseUrl = 'http://api.geonames.org';
  
  static Future<List<LocationSuggestion>> searchCities(String query) async {
    if (query.trim().isEmpty || query.length < 2) {
      return [];
    }

    try {
      final url = Uri.parse(
        '$_geonamesBaseUrl/searchJSON?name_startsWith=${Uri.encodeComponent(query.trim())}&maxRows=10&featureClass=P&username=$_geonamesUsername'
      );
      
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['geonames'] != null) {
          return (data['geonames'] as List)
              .map((item) => LocationSuggestion.fromGeonames(item))
              .take(10)
              .toList();
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error fetching location suggestions: $e');
      }
    }
    
    return [];
  }

  static Future<LocationSuggestion?> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (kDebugMode) {
          debugPrint('Location services are disabled.');
        }
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (kDebugMode) {
            debugPrint('Location permissions are denied');
          }
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (kDebugMode) {
          debugPrint('Location permissions are permanently denied, cannot request permissions.');
        }
        return null;
      }

      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 15),
      );

      return await _reverseGeocode(position.latitude, position.longitude);
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting current location: $e');
      }
      return null;
    }
  }

  static Future<LocationSuggestion?> _reverseGeocode(double latitude, double longitude) async {
    try {
      final url = Uri.parse(
        '$_geonamesBaseUrl/findNearbyPlaceNameJSON?lat=$latitude&lng=$longitude&username=$_geonamesUsername'
      );
      
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      
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
      if (kDebugMode) {
        debugPrint('Error reverse geocoding: $e');
      }
    }
    return null;
  }
}

class LocationSuggestion {
  final String name;
  final String country;
  final String? adminName;
  
  LocationSuggestion({
    required this.name,
    required this.country,
    this.adminName,
  });
  
  factory LocationSuggestion.fromGeonames(Map<String, dynamic> json) {
    return LocationSuggestion(
      name: json['name'] as String,
      country: json['countryName'] as String,
      adminName: json['adminName1'] as String?,
    );
  }
  
  String get displayName {
    if (adminName != null && adminName!.isNotEmpty && adminName != name) {
      return '$name, $adminName, $country';
    }
    return '$name, $country';
  }
  
  
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