// lib/screens/base_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/base_provider.dart';
import '../core/app_core.dart';
import '../utils/dialog_utils.dart';
import '../widgets/common_widgets.dart';

mixin ScreenHelpers<T extends StatefulWidget> on State<T> {
  AuthProvider get auth => Provider.of<AuthProvider>(context, listen: false);

  void navigateTo(String route, {Object? arguments}) => Navigator.pushNamed(context, route, arguments: arguments);
  void navigateBack([dynamic result]) => Navigator.pop(context, result);
  void navigateToHome() => navigateTo(AppRoutes.home);

  void showSuccess(String message) => UiUtils.showSnackBar(context, message, backgroundColor: Colors.green);
  void showError(String message) => UiUtils.showSnackBar(context, message, backgroundColor: AppTheme.error);
  void showInfo(String message) => UiUtils.showSnackBar(context, message);

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
  }) => buildListWithRefresh<I>(
    items: items,
    itemBuilder: itemBuilder,
    onRefresh: onRefresh,
    emptyState: emptyState,
    padding: padding,
  );

  Widget buildTabScaffold({
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

  Widget buildTabContent({
    required List<Tab> tabs,
    required List<Widget> tabViews,
    TabController? controller,
  }) => buildTabScaffold(tabs: tabs, tabViews: tabViews, controller: controller);

  Widget buildLoadingState({String? message}) => CommonStates.loading(message);
  
  Widget buildErrorState({required String message, VoidCallback? onRetry, String? retryText}) => 
      CommonStates.error(message: message, onRetry: onRetry, retryText: retryText);

  Widget buildEmptyState({required IconData icon, required String title, String? subtitle, String? buttonText, VoidCallback? onButtonPressed}) => 
      CommonStates.empty(icon: icon, title: title, subtitle: subtitle, buttonText: buttonText, onButtonPressed: onButtonPressed);

  Future<void> runAsync(Future<void> Function() operation) async {
    await operation();
  }

  bool get isLoading => false; 
}

abstract class BaseScreen<T extends StatefulWidget> extends State<T> with ScreenHelpers<T> {
  String get screenTitle;
  Widget buildContent();
  
  bool get showDrawer => true;
  List<Widget> get actions => [];
  Widget? get floatingActionButton => null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: buildAppBar(),
      drawer: showDrawer ? _buildDrawer() : null,
      body: buildContent(),
      floatingActionButton: floatingActionButton,
    );
  }

  PreferredSizeWidget? buildAppBar() => AppBar(
    backgroundColor: AppTheme.background,
    title: Text(screenTitle),
    actions: actions,
  );

  PreferredSizeWidget buildStandardAppBar({
    List<Widget>? actions,
    String? title,
  }) => AppBar(
    backgroundColor: AppTheme.background,
    title: Text(title ?? screenTitle),
    actions: actions ?? this.actions,
  );

  Widget _buildDrawer() => Drawer(
    backgroundColor: AppTheme.background,
    child: ListView(
      children: [
        DrawerHeader(
          decoration: const BoxDecoration(color: AppTheme.primary),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.music_note, color: Colors.black, size: 48),
              const SizedBox(height: 16),
              Text(auth.displayName, style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
              Text('ID: ${auth.userId ?? "Unknown"}', style: const TextStyle(color: Colors.black54)),
            ],
          ),
        ),
        _drawerItem(Icons.home, 'Home', AppRoutes.home),
        _drawerItem(Icons.library_music, 'Playlists', AppRoutes.publicPlaylists),
        _drawerItem(Icons.people, 'Friends', AppRoutes.friends),
        _drawerItem(Icons.search, 'Search', AppRoutes.trackSearch),
        const Divider(color: Colors.grey),
        ListTile(
          leading: const Icon(Icons.logout, color: Colors.orange),
          title: const Text('Sign Out', style: TextStyle(color: Colors.orange)),
          onTap: () {
            Navigator.pop(context);
            auth.logout();
          },
        ),
      ],
    ),
  );

  Widget _drawerItem(IconData icon, String title, String route) => ListTile(
    leading: Icon(icon, color: Colors.white),
    title: Text(title, style: const TextStyle(color: Colors.white)),
    onTap: () {
      Navigator.pop(context);
      navigateTo(route);
    },
  );
}
