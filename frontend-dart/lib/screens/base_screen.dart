// lib/screens/base_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../core/consolidated_core.dart';
import '../widgets/app_widgets.dart';
import '../utils/dialog_utils.dart';

abstract class BaseScreen<T extends StatefulWidget> extends State<T> {
  String get screenTitle;
  Widget buildContent();
  
  List<Widget> get actions => [];
  Widget? get floatingActionButton => null;
  bool get showBackButton => true;

  AuthProvider get auth => Provider.of<AuthProvider>(context, listen: false);

  void navigateTo(String route, {Object? arguments}) => 
      Navigator.pushNamed(context, route, arguments: arguments);
  void navigateBack([dynamic result]) => Navigator.pop(context, result);
  void navigateToHome() => navigateTo(AppRoutes.home);

  void showSuccess(String message) => AppWidgets.showSnackBar(context, message, backgroundColor: Colors.green);
  void showError(String message) => AppWidgets.showSnackBar(context, message, backgroundColor: AppTheme.error);
  void showInfo(String message) => AppWidgets.showSnackBar(context, message);

  Future<bool> showConfirmDialog(String title, String message, {bool isDangerous = false}) async =>
      await DialogUtils.showConfirmDialog(context, title: title, message: message, isDangerous: isDangerous);

  Future<String?> showTextInputDialog(String title, {String? initialValue, String? hintText}) async =>
      await DialogUtils.showTextInputDialog(context, title: title, initialValue: initialValue, hintText: hintText);

  T getProvider<T>({bool listen = false}) => Provider.of<T>(context, listen: listen);

  Future<void> runAsyncAction(
    Future<void> Function() operation, {
    String? successMessage,
    String? errorMessage,
  }) async {
    try {
      await operation();
      if (successMessage != null) showSuccess(successMessage);
    } catch (e) {
      showError(errorMessage ?? e.toString());
    }
  }

  Widget buildLoadingState({String? message}) => AppWidgets.loading(message);
  Widget buildErrorState({required String message, VoidCallback? onRetry, String? retryText}) => 
      AppWidgets.errorState(message: message, onRetry: onRetry, retryText: retryText);
  Widget buildEmptyState({required IconData icon, required String title, String? subtitle, String? buttonText, VoidCallback? onButtonPressed}) => 
      AppWidgets.emptyState(icon: icon, title: title, subtitle: subtitle, buttonText: buttonText, onButtonPressed: onButtonPressed);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        title: Text(screenTitle),
        actions: actions,
        automaticallyImplyLeading: showBackButton,
      ),
      body: buildContent(),
      floatingActionButton: floatingActionButton,
    );
  }
}
