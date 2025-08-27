import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:dio/dio.dart';
import 'package:form_validator/form_validator.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';
import 'locator_core.dart';
import '../providers/connectivity_providers.dart';
import 'navigation_core.dart';

abstract class BaseProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  bool get hasError => _errorMessage != null;
  bool get hasSuccess => _successMessage != null;
  bool get isReady => !_isLoading && !hasError;

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    if (loading) clearMessages();
    notifyListeners();
  }

  void setError(String error) {
    _errorMessage = error;
    _successMessage = null;
    _isLoading = false;
    notifyListeners();
  }

  void setSuccess(String message) {
    _successMessage = message;
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }

  Future<T?> executeAsync<T>(
    Future<T> Function() operation, {
    String? successMessage,
    String? errorMessage,
  }) async {
    setLoading(true);
    try {
      final result = await operation();
      if (successMessage != null) {
        setSuccess(successMessage);
      } else {
        setLoading(false);
      }
      return result;
    } catch (e) {
      if (kDebugMode) {
        final errorString = e.toString().toLowerCase();
        final isUserCancellation = errorString.contains('popup_closed') || 
                                  errorString.contains('cancelled') ||
                                  errorString.contains('sign-in was cancelled') ||
                                  errorString.contains('facebook login failed') ||
                                  errorString.contains('login cancelled') ||
                                  errorString.contains('user cancelled');
        
        debugPrint('[BaseProvider] executeAsync error: ${_extractErrorMessage(e)}');
        
        if (e is! DioException && !isUserCancellation) {
          debugPrint('[BaseProvider] Full error: $e');
          debugPrint('[BaseProvider] Stack trace: ${StackTrace.current}');
        }
      }
      setError(errorMessage ?? _extractErrorMessage(e));
      return null;
    }
  }

  Future<bool> executeBool(
    Future<void> Function() operation, {
    String? successMessage,
    String? errorMessage,
  }) async {
    setLoading(true);
    try {
      await operation();
      if (successMessage != null) {
        setSuccess(successMessage);
      } else {
        setLoading(false);
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        final errorString = e.toString().toLowerCase();
        final isUserCancellation = errorString.contains('popup_closed') || 
                                  errorString.contains('cancelled') ||
                                  errorString.contains('sign-in was cancelled') ||
                                  errorString.contains('facebook login failed') ||
                                  errorString.contains('login cancelled') ||
                                  errorString.contains('user cancelled');
        
        debugPrint('[BaseProvider] executeBool error: ${_extractErrorMessage(e)}');
        
        if (e is! DioException && !isUserCancellation) {
          debugPrint('[BaseProvider] Full error: $e');
          debugPrint('[BaseProvider] Stack trace: ${StackTrace.current}');
        }
      }
      setError(errorMessage ?? _extractErrorMessage(e));
      return false;
    }
  }
  
  String _extractErrorMessage(dynamic error) {
    if (error is DioException) {

      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.connectionError) {

        try {
          final connectivity = getIt<ConnectivityProvider>();
          connectivity.checkConnection();
        } catch (e) {
          AppLogger.debug('Failed to force connectivity check', 'BaseProvider');
        }
        return 'No connection to server. Please check your internet connection.';
      }

      if (error.response?.data is Map) {
        final data = error.response!.data as Map<String, dynamic>;
        
        if (kDebugMode) {
          debugPrint('[BaseProvider] ${error.response?.statusCode} error response data: $data');
        }
        
        if (data['detail'] != null) {
          return data['detail'].toString();
        }
        
        if (data['error'] != null) {
          if (data['error'] is List) {
            final errorList = (data['error'] as List).cast<String>();
            return errorList.join('\n');
          }
          return data['error'].toString();
        }
        
        if (data['message'] != null) {
          return data['message'].toString();
        }
        
        final errors = <String>[];
        for (final entry in data.entries) {
          if (entry.value is List) {
            final fieldErrors = (entry.value as List).cast<String>();
            errors.addAll(fieldErrors);
          } else if (entry.value is String) {
            errors.add(entry.value);
          }
        }
        
        if (errors.isNotEmpty) {
          return errors.join('\n');
        }
      } else if (error.response?.data is List) {
        final dataList = error.response!.data as List;
        final errorMessages = dataList.map((e) => e.toString()).toList();
        if (errorMessages.isNotEmpty) {
          return errorMessages.join('\n');
        }
      } else if (error.response?.data is String) {
        return error.response!.data.toString();
      }
      
      switch (error.response?.statusCode) {
        case 401:
          return 'Authentication required. Please log in again.';
        case 403:
          return 'You do not have permission to perform this action.';
        case 404:
          return 'The requested resource was not found.';
        case 500:
          return 'Server error. Please try again later.';
        default:
          return 'An error occurred. Please try again.';
      }
    }
    
    return error.toString();
  }
}

class AppConstants {
  static const String appName = 'Music Room';
  static const String version = '1.0.0';
  static const String defaultApiBaseUrl = 'http://localhost:8000';
  static const String contentTypeJson = 'application/json';
  static const String authorizationPrefix = 'Token';
  static const int minPasswordLength = 4;
}

class AppStrings {
  static const String confirmLogout = 'Are you sure you want to sign out?';
  static const String networkError = 'Network error. Please check your connection.';
}

class AppRoutes {
  static const String auth = '/auth';
  static const String profile = '/profile';
  static const String playlistEditor = '/playlist_editor';
  static const String playlistDetail = '/playlist_detail';
  static const String trackDetail = '/track_detail';
  static const String trackSearch = '/track_search';
  static const String publicPlaylists = '/public_playlists';
  static const String friends = '/friends';
  static const String addFriend = '/add_friend';
  static const String friendRequests = '/friend_requests';
  static const String playlistSharing = '/playlist_sharing';
  static const String player = '/player';
  static const String userPasswordChange = '/user_password_change';
  static const String socialNetworkLink = '/social_network_link';
  static const String signupOtp = '/signup_otp';
  static const String userPage = '/user_page';
  static const String adminDashboard = '/admin_dashboard';
}

class FormatUtils {
  static String formatDuration(Duration duration) {
    final h = duration.inHours, m = duration.inMinutes.remainder(60), s = duration.inSeconds.remainder(60);
    String pad(int n) => n.toString().padLeft(2, '0');
    return h > 0 ? '${pad(h)}:${pad(m)}:${pad(s)}' : '${pad(m)}:${pad(s)}';
  }
}

class AppValidators {
  static String? required(String? value) {
    if (value == null || value.trim().isEmpty) return 'This field is required';
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.isEmpty) return 'Please enter an email address';
    if (value != value.trim()) return 'Email cannot have leading or trailing spaces';
    if (!RegExp(r'^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$').hasMatch(value)) return 'Enter a valid email address';
    return null;
  }
  
  static String? password(String? value, [int minLength = 8]) {
    if (value == null || value.isEmpty) return 'Please enter a password';
    if (value.length < minLength) return 'Password must be at least $minLength characters';
    if (value.contains(' ')) return 'The password must not contain spaces';
    return null;
  }
  
  static String? username(String? value) {
    if (value == null || value.isEmpty) return 'Please enter a username';
    if (value != value.trim()) return 'Username cannot have leading or trailing spaces';
    if (value.length > 20) return 'Username must be less than 20 characters';
    if (!RegExp(r'^\w+$').hasMatch(value)) return 'Username can only contain letters, numbers, and underscores';
    return null;
  }

  static String? phoneNumber(String? value, [bool required = false]) {
    if (!required && (value?.isEmpty ?? true)) return null;
    if (value == null || value.trim().isEmpty) return required ? 'Please enter a phone number' : null;
    try {
      return PhoneNumber.parse(value.trim()).isValid() ? null : 'Please enter a valid phone number';
    } catch (e) {
      return 'Please enter a valid phone number';
    }
  }
  
  static String? bio(String? value) => ValidationBuilder().maxLength(500, 'Bio must be less than 500 characters').build()(value);
}
