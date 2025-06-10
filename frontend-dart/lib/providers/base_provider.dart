// lib/providers/base_provider.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';

mixin BaseProvider on ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;
  bool get isReady => !_isLoading;

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
    notifyListeners();
  }

  Future<T?> execute<T>(Future<T> Function() operation) async {
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

mixin CommonProviderOperations<T> on ChangeNotifier, BaseProvider {
  final ApiService _api = ApiService();
  List<T> _items = [];
  T? _selectedItem;

  List<T> get items => List.unmodifiable(_items);
  T? get selectedItem => _selectedItem;
  bool get hasItems => _items.isNotEmpty;
  int get itemCount => _items.length;

  Future<void> fetchItems(String token, {String? endpoint}) async {
    final result = await execute(() => _fetchItemsFromApi(token, endpoint));
    if (result != null) {
      _items = result;
    }
  }

  Future<T?> createItem(Map<String, dynamic> data, String token, {String? endpoint}) async {
    return execute(() async {
      final item = await _createItemInApi(data, token, endpoint);
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
      await _updateItemInApi(id, data, token, endpoint);
      await refreshItems(token);
      return true;
    });
    return result ?? false;
  }

  Future<bool> deleteItem(String id, String token, {String? endpoint}) async {
    final result = await execute(() async {
      await _deleteItemInApi(id, token, endpoint);
      _items.removeWhere((item) => _getItemId(item) == id);
      if (_selectedItem != null && _getItemId(_selectedItem!) == id) {
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
      return _items.firstWhere((item) => _getItemId(item) == id);
    } catch (e) {
      return null;
    }
  }

  Future<List<T>> _fetchItemsFromApi(String token, String? endpoint);
  Future<T?> _createItemInApi(Map<String, dynamic> data, String token, String? endpoint);
  Future<void> _updateItemInApi(String id, Map<String, dynamic> data, String token, String? endpoint);
  Future<void> _deleteItemInApi(String id, String token, String? endpoint);
  String _getItemId(T item);
}
