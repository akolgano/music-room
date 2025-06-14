// lib/screens/base_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/base_provider.dart';
import '../core/app_core.dart';
import '../utils/dialog_utils.dart';
import '../widgets/unified_components.dart';

abstract class BaseScreen<T extends StatefulWidget> extends State<T> {
  
  String get screenTitle;
  Widget buildContent();
  
  List<Widget> get actions => [];
  Widget? get floatingActionButton => null;
  bool get showDrawer => true;
  bool get isLoading => false;

  AuthProvider get auth => Provider.of<AuthProvider>(context, listen: false);

  void navigateTo(String route, {Object? arguments}) => Navigator.pushNamed(context, route, arguments: arguments);
  void navigateBack([dynamic result]) => Navigator.pop(context, result);
  void navigateToHome() => navigateTo(AppRoutes.home);

  void showSuccess(String message) => UnifiedComponents.showSnackBar(context, message, backgroundColor: Colors.green);
  void showError(String message) => UnifiedComponents.showSnackBar(context, message, backgroundColor: AppTheme.error);
  void showInfo(String message) => UnifiedComponents.showSnackBar(context, message);

  Future<bool> showConfirmDialog(String title, String message, {bool isDangerous = false}) async =>
      await DialogUtils.showConfirmDialog(context, title: title, message: message, isDangerous: isDangerous) ?? false;

  Future<String?> showTextInputDialog(String title, {String? initialValue, String? hintText}) async =>
      await DialogUtils.showTextInputDialog(context, title: title, initialValue: initialValue, hintText: hintText);

  T getProvider<T>({bool listen = false}) => Provider.of<T>(context, listen: listen);

  Future<void> runAsyncAction(
    Future<void> Function() operation, {
    String? loadingMessage,
    String? successMessage,
    String? errorMessage,
  }) async {
    try {
      if (loadingMessage != null) showInfo(loadingMessage);
      await operation();
      if (successMessage != null) showSuccess(successMessage);
    } catch (e) {
      showError(errorMessage ?? e.toString());
    }
  }

  Future<void> runAsync(Future<void> Function() operation) async {
    try {
      await operation();
    } catch (e) {
      showError(e.toString());
    }
  }

  Widget buildConsumerContent<P extends ChangeNotifier>({
    required Widget Function(BuildContext, P) builder,
    Widget Function(String)? errorBuilder,
    Widget Function()? loadingBuilder,
  }) => Consumer<P>(
    builder: (context, provider, _) {
      if (provider is StateManagement) {
        if (provider.isLoading) return loadingBuilder?.call() ?? buildLoadingState();
        if (provider.hasError) return errorBuilder?.call(provider.errorMessage!) ?? buildErrorState(message: provider.errorMessage!);
      }
      return builder(context, provider);
    },
  );

  Widget buildListWithRefresh<I>({
    required List<I> items,
    required Widget Function(I, int) itemBuilder,
    required Future<void> Function() onRefresh,
    Widget? emptyState,
    EdgeInsets? padding,
  }) {
    if (items.isEmpty && emptyState != null) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(height: MediaQuery.of(context).size.height * 0.6, child: emptyState),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppTheme.primary,
      child: ListView.builder(
        padding: padding ?? const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (context, index) => itemBuilder(items[index], index),
      ),
    );
  }

  Widget buildListContent<I>({
    required List<I> items,
    required Widget Function(I, int) itemBuilder,
    required Future<void> Function() onRefresh,
    Widget? emptyState,
    EdgeInsets? padding,
  }) {
    return buildListWithRefresh<I>(
      items: items,
      itemBuilder: itemBuilder,
      onRefresh: onRefresh,
      emptyState: emptyState,
      padding: padding,
    );
  }

  Widget buildTabContent({
    required List<Tab> tabs,
    required List<Widget> tabViews,
    TabController? controller,
  }) => DefaultTabController(
    length: tabs.length,
    child: Column(
      children: [
        TabBar(controller: controller, labelColor: AppTheme.primary, unselectedLabelColor: Colors.grey, tabs: tabs),
        Expanded(child: TabBarView(controller: controller, children: tabViews)),
      ],
    ),
  );

  Widget buildTabScaffold({
    required List<Tab> tabs,
    required List<Widget> tabViews,
    TabController? controller,
  }) => buildTabContent(tabs: tabs, tabViews: tabViews, controller: controller);

  Widget buildLoadingState({String? message}) => UnifiedComponents.loading(message);
  
  Widget buildErrorState({required String message, VoidCallback? onRetry, String? retryText}) => 
      UnifiedComponents.error(message: message, onRetry: onRetry, retryText: retryText);

  Widget buildEmptyState({required IconData icon, required String title, String? subtitle, String? buttonText, VoidCallback? onButtonPressed}) => 
      UnifiedComponents.emptyState(icon: icon, title: title, subtitle: subtitle, buttonText: buttonText, onButtonPressed: onButtonPressed);

  PreferredSizeWidget buildStandardAppBar({List<Widget>? actions}) {
    return AppBar(
      backgroundColor: AppTheme.background,
      title: Text(screenTitle),
      actions: actions ?? this.actions,
    );
  }

  PreferredSizeWidget? buildAppBar() {
    return buildStandardAppBar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: buildAppBar(),
      body: buildContent(),
      floatingActionButton: floatingActionButton,
    );
  }
}
