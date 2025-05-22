// lib/screens/base_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/music_provider.dart';
import '../extensions/context_extensions.dart';

abstract class BaseScreen<T extends StatefulWidget> extends State<T> {
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  AuthProvider get authProvider => context.authProvider;
  MusicProvider get musicProvider => context.musicProvider;
  AuthProvider get appProvider => context.authProvider;

  String get screenTitle;
  Widget buildBody();
  PreferredSizeWidget? buildAppBar() => AppBar(title: Text(screenTitle));

  void setLoading(bool loading) {
    if (mounted) {
      setState(() {
        _isLoading = loading;
      });
    }
  }

  void handleError([String? error]) {
    if (error != null) {
      setState(() {
        _errorMessage = error;
      });
      showError(error);
    }
  }

  void showSuccess(String message) {
    context.showSuccessSnackBar(message);
  }

  void showError(String message) {
    context.showErrorSnackBar(message);
  }

  void showInfo(String message) {
    context.showSnackBar(message: message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(),
      body: buildBody(),
    );
  }
}
