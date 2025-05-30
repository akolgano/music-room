// lib/screens/base_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/app_provider.dart';
import '../core/theme.dart';

abstract class BaseScreen<T extends StatefulWidget> extends State<T> {
  AuthProvider get auth => Provider.of<AuthProvider>(context, listen: false);
  AppProvider get app => Provider.of<AppProvider>(context, listen: false);
  
  String get screenTitle;
  Widget buildContent();
  
  PreferredSizeWidget? buildAppBar() => AppBar(
    backgroundColor: AppTheme.background,
    title: Text(screenTitle),
  );

  List<Widget> get actions => [];

  Widget? get floatingActionButton => null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: buildAppBar(),
      body: buildContent(),
      floatingActionButton: floatingActionButton,
    );
  }

  void showSuccess(String message) => showSnackBar(context, message);
  void showError(String message) => showSnackBar(context, message, isError: true);

  void showSnackBar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppTheme.error : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<T?> runAsync<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } catch (e) {
      showError(e.toString());
      return null;
    }
  }
}
