import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

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
    
    // Return fallback popular cities if API fails
    return _getFallbackSuggestions(query);
  }

  static List<LocationSuggestion> _getFallbackSuggestions(String query) {
    final popularCities = [
      LocationSuggestion(name: 'New York', country: 'United States', adminName: 'New York'),
      LocationSuggestion(name: 'London', country: 'United Kingdom', adminName: 'England'),
      LocationSuggestion(name: 'Tokyo', country: 'Japan', adminName: 'Tokyo'),
      LocationSuggestion(name: 'Paris', country: 'France', adminName: 'Île-de-France'),
      LocationSuggestion(name: 'Los Angeles', country: 'United States', adminName: 'California'),
      LocationSuggestion(name: 'Toronto', country: 'Canada', adminName: 'Ontario'),
      LocationSuggestion(name: 'Sydney', country: 'Australia', adminName: 'New South Wales'),
      LocationSuggestion(name: 'Berlin', country: 'Germany', adminName: 'Berlin'),
      LocationSuggestion(name: 'Singapore', country: 'Singapore', adminName: 'Singapore'),
      LocationSuggestion(name: 'Mumbai', country: 'India', adminName: 'Maharashtra'),
    ];
    
    final queryLower = query.toLowerCase();
    return popularCities
        .where((city) => city.name.toLowerCase().contains(queryLower))
        .toList();
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