// lib/providers/base_provider.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';

mixin StateManagement on ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;
  bool get isReady => !_isLoading && !hasError;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setError(String error) {
    _errorMessage = error;
    _isLoading = false;
    notifyListeners();
  }

  Future<T?> execute<T>(Future<T> Function() operation) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await operation();
      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }
}

mixin CrudOperations<T> on ChangeNotifier, StateManagement {
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
    final result = await execute(() => fetchFromApi(token, endpoint: endpoint));
    if (result != null) {
      _items = result;
    }
  }

  Future<T?> createItem(Map<String, dynamic> data, String token, {String? endpoint}) async {
    return execute(() async {
      final item = await createInApi(data, token, endpoint: endpoint);
      if (item != null) {
        _items.add(item);
        notifyListeners();
        return item;
      }
      throw Exception('Failed to create item');
    });
  }

  Future<bool> updateItem(String id, Map<String, dynamic> data, String token, {String? endpoint}) async {
    final result = await execute(() async {
      await updateInApi(id, data, token, endpoint: endpoint);
      await refreshItems(token);
      return true;
    });
    return result ?? false;
  }

  Future<bool> deleteItem(String id, String token, {String? endpoint}) async {
    final result = await execute(() async {
      await deleteInApi(id, token, endpoint: endpoint);
      _items.removeWhere((item) => getItemId(item) == id);
      if (_selectedItem != null && getItemId(_selectedItem!) == id) {
        _selectedItem = null;
      }
      notifyListeners();
      return true;
    });
    return result ?? false;
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
}

abstract class BaseProvider extends ChangeNotifier with StateManagement {
  final ApiService api = ApiService();

  Future<void> performAction(
    Future<void> Function() action, {
    String? successMessage,
    String? errorMessage,
    VoidCallback? onSuccess,
    VoidCallback? onError,
  }) async {
    setLoading(true);
    clearError();

    try {
      await action();
      onSuccess?.call();
    } catch (e) {
      final message = errorMessage ?? e.toString();
      setError(message);
      onError?.call();
    } finally {
      setLoading(false);
    }
  }
}
