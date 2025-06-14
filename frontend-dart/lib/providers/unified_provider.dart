// lib/providers/unified_provider.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';

mixin UnifiedStateManagement on ChangeNotifier {
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

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearSuccess() {
    _successMessage = null;
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    if (loading) {
      _errorMessage = null;
      _successMessage = null;
    }
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
    bool showLoading = true,
  }) async {
    if (showLoading) setLoading(true);
    clearMessages();

    try {
      final result = await operation();
      if (successMessage != null) setSuccess(successMessage);
      return result;
    } catch (e) {
      setError(errorMessage ?? e.toString());
      return null;
    } finally {
      if (showLoading) setLoading(false);
    }
  }

  Future<bool> executeBool(
    Future<void> Function() operation, {
    String? successMessage,
    String? errorMessage,
    bool showLoading = true,
  }) async {
    final result = await executeAsync<bool>(
      () async {
        await operation();
        return true;
      },
      successMessage: successMessage,
      errorMessage: errorMessage,
      showLoading: showLoading,
    );
    return result ?? false;
  }
}

mixin UnifiedCrudOperations<T> on ChangeNotifier, UnifiedStateManagement {
  final ApiService _api = ApiService();
  List<T> _items = [];
  T? _selectedItem;

  List<T> get items => List.unmodifiable(_items);
  T? get selectedItem => _selectedItem;
  bool get hasItems => _items.isNotEmpty;
  int get itemCount => _items.length;

  Future<List<T>> fetchFromApi(String token, {String? endpoint});
  Future<T?> createInApi(Map<String, dynamic> data, String token, {String? endpoint});
  Future<void> updateInApi(String id, Map<String, dynamic> data, String token, {String? endpoint});
  Future<void> deleteInApi(String id, String token, {String? endpoint});
  String getItemId(T item);

  Future<void> fetchItems(String token, {String? endpoint}) async {
    final result = await executeAsync(
      () => fetchFromApi(token, endpoint: endpoint),
      errorMessage: 'Failed to fetch items',
    );
    if (result != null) {
      _items = result;
    }
  }

  Future<T?> createItem(Map<String, dynamic> data, String token, {String? endpoint}) async {
    return executeAsync(
      () async {
        final item = await createInApi(data, token, endpoint: endpoint);
        if (item != null) {
          _items.add(item);
          notifyListeners();
          return item;
        }
        throw Exception('Failed to create item');
      },
      successMessage: 'Item created successfully',
      errorMessage: 'Failed to create item',
    );
  }

  Future<bool> updateItem(String id, Map<String, dynamic> data, String token, {String? endpoint}) async {
    return executeBool(
      () async {
        await updateInApi(id, data, token, endpoint: endpoint);
        await refreshItems(token, endpoint: endpoint);
      },
      successMessage: 'Item updated successfully',
      errorMessage: 'Failed to update item',
    );
  }

  Future<bool> deleteItem(String id, String token, {String? endpoint}) async {
    return executeBool(
      () async {
        await deleteInApi(id, token, endpoint: endpoint);
        _items.removeWhere((item) => getItemId(item) == id);
        if (_selectedItem != null && getItemId(_selectedItem!) == id) {
          _selectedItem = null;
        }
        notifyListeners();
      },
      successMessage: 'Item deleted successfully',
      errorMessage: 'Failed to delete item',
    );
  }

  void selectItem(T? item) {
    _selectedItem = item;
    notifyListeners();
  }

  Future<void> refreshItems(String token, {String? endpoint}) async {
    await fetchItems(token, endpoint: endpoint);
  }

  void clearItems() {
    _items.clear();
    _selectedItem = null;
    notifyListeners();
  }

  T? findItemById(String id) {
    try {
      return _items.firstWhere((item) => getItemId(item) == id);
    } catch (e) {
      return null;
    }
  }

  void addItem(T item) {
    _items.add(item);
    notifyListeners();
  }

  void removeItem(String id) {
    _items.removeWhere((item) => getItemId(item) == id);
    if (_selectedItem != null && getItemId(_selectedItem!) == id) {
      _selectedItem = null;
    }
    notifyListeners();
  }

  void updateItemInList(T updatedItem) {
    final index = _items.indexWhere((item) => getItemId(item) == getItemId(updatedItem));
    if (index != -1) {
      _items[index] = updatedItem;
      if (_selectedItem != null && getItemId(_selectedItem!) == getItemId(updatedItem)) {
        _selectedItem = updatedItem;
      }
      notifyListeners();
    }
  }
}

class UnifiedApiResponse<T> {
  final bool success;
  final T? data;
  final String? error;
  final String? message;

  UnifiedApiResponse.success(this.data, [this.message]) 
    : success = true, error = null;
  
  UnifiedApiResponse.error(this.error) 
    : success = false, data = null, message = null;
}

class UnifiedValidators {
  static String? required(String? value, [String? fieldName]) {
    if (value?.isEmpty ?? true) {
      return 'Please enter ${fieldName ?? 'this field'}';
    }
    return null;
  }

  static String? email(String? value) {
    if (value?.isEmpty ?? true) return 'Please enter an email';
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  static String? password(String? value, [int minLength = 8]) {
    if (value?.isEmpty ?? true) return 'Please enter password';
    if (value!.length < minLength) {
      return 'Password must be at least $minLength characters';
    }
    return null;
  }

  static String? length(String? value, int maxLength, [String? fieldName]) {
    if (value != null && value.length > maxLength) {
      return '${fieldName ?? 'Field'} must be less than $maxLength characters';
    }
    return null;
  }

  static String? range(String? value, int min, int max, [String? fieldName]) {
    if (value != null) {
      if (value.length < min) {
        return '${fieldName ?? 'Field'} must be at least $min characters';
      }
      if (value.length > max) {
        return '${fieldName ?? 'Field'} must be less than $max characters';
      }
    }
    return null;
  }

  static String? username(String? value) {
    if (value?.isEmpty ?? true) return 'Please enter a username';
    if (value!.length < 3) return 'Username must be at least 3 characters';
    if (value.length > 30) return 'Username must be less than 30 characters';
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
      return 'Username can only contain letters, numbers, and underscores';
    }
    return null;
  }

  static String? phoneNumber(String? value) {
    if (value?.isEmpty ?? true) return null; 
    if (!RegExp(r'^\+?[\d\s\-\(\)]+$').hasMatch(value!)) {
      return 'Please enter a valid phone number';
    }
    return null;
  }

  static String? Function(String?) combine(List<String? Function(String?)> validators) {
    return (String? value) {
      for (final validator in validators) {
        final result = validator(value);
        if (result != null) return result;
      }
      return null;
    };
  }
}

enum LoadingState { idle, loading, success, error }

class AsyncResult<T> {
  final bool isSuccess;
  final T? data;
  final String? error;
  final String? message;

  AsyncResult.success(this.data, [this.message]) 
    : isSuccess = true, error = null;
  
  AsyncResult.error(this.error) 
    : isSuccess = false, data = null, message = null;

  bool get isError => !isSuccess;
}

abstract class UnifiedBaseProvider extends ChangeNotifier with UnifiedStateManagement {
  final ApiService api = ApiService();

  Future<void> performAction(
    Future<void> Function() action, {
    String? successMessage,
    String? errorMessage,
    VoidCallback? onSuccess,
    VoidCallback? onError,
  }) async {
    final success = await executeBool(
      action,
      successMessage: successMessage,
      errorMessage: errorMessage,
    );
    
    if (success) {
      onSuccess?.call();
    } else {
      onError?.call();
    }
  }
}
