import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../core/theme_utils.dart';
import '../core/constants.dart';
import '../widgets/app_widgets.dart';

abstract class BaseScreen<T extends StatefulWidget> extends State<T> {
  String get screenTitle;
  Widget buildContent();
  List<Widget> get actions => [];
  Widget? get floatingActionButton => null;
  bool get showBackButton => true;
  bool get showMiniPlayer => true;

  AuthProvider get auth => Provider.of<AuthProvider>(context, listen: false);

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
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(child: buildContent()),
            if (showMiniPlayer) const MiniPlayerWidget()
          ],
        ),
      ),
      floatingActionButton: floatingActionButton != null && showMiniPlayer
          ? Container(
              margin: const EdgeInsets.only(bottom: 80),
              child: floatingActionButton,
            )
          : floatingActionButton,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  void navigateTo(String route, {Object? arguments}) {
    if (!mounted) return;
    Navigator.pushNamed(context, route, arguments: arguments);
  }

  void navigateBack([dynamic result]) {
    if (!mounted) return;
    Navigator.pop(context, result);
  }

  void navigateToHome() => navigateTo(AppRoutes.home);

  void showSuccess(String message) {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) AppWidgets.showSnackBar(context, message, backgroundColor: Colors.green);
    });
  }

  void showError(String message) {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) AppWidgets.showSnackBar(context, message, backgroundColor: AppTheme.error);
    });
  }

  void showInfo(String message) {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) AppWidgets.showSnackBar(context, message);
    });
  }

  Future<bool> showConfirmDialog(String title, String message, {bool isDangerous = false}) async {
    if (!mounted) return false;
    return await AppWidgets.showConfirmDialog(context, title: title, message: message, isDangerous: isDangerous);
  }

  Future<String?> showTextInputDialog(String title, {String? initialValue, String? hintText}) async {
    if (!mounted) return null;
    return await AppWidgets.showTextInputDialog(context, title: title, initialValue: initialValue, hintText: hintText);
  }

  P getProvider<P>({bool listen = false}) => Provider.of<P>(context, listen: listen);

  Future<void> runAsyncAction(Future<void> Function() operation, {String? successMessage, String? errorMessage}) async {
    try {
      await operation();
      if (mounted && successMessage != null) showSuccess(successMessage);
    } catch (e) {
      if (mounted) showError(errorMessage ?? e.toString());
    }
  }

  Widget buildLoadingState({String? message}) => AppWidgets.loading(message);

  Widget buildErrorState({required String message, VoidCallback? onRetry, String? retryText}) => 
      AppWidgets.errorState(message: message, onRetry: onRetry, retryText: retryText);

  Widget buildEmptyState({required IconData icon, required String title, String? subtitle, String? buttonText, VoidCallback? onButtonPressed}) => 
      AppWidgets.emptyState(icon: icon, title: title, subtitle: subtitle, buttonText: buttonText, onButtonPressed: onButtonPressed);

  Widget buildConsumerContent<P extends ChangeNotifier>({
    required Widget Function(BuildContext context, P provider) builder,
  }) {
    return Consumer<P>(builder: (context, provider, _) => builder(context, provider));
  }

  Widget buildListWithRefresh<E>({required List<E> items, required Widget Function(E, int) itemBuilder,
    required Future<void> Function() onRefresh,
    Widget? emptyState, EdgeInsets? padding,
  }) {
    return AppWidgets.refreshableList<E>(items: items, itemBuilder: itemBuilder, onRefresh: onRefresh, emptyState: emptyState, padding: padding);
  }

  Widget buildListContent<E>({
    required List<E> items,
    required Widget Function(E, int) itemBuilder,
    required Future<void> Function() onRefresh,
    Widget? emptyState,
    EdgeInsets? padding,
  }) {
    return buildListWithRefresh<E>(items: items, itemBuilder: itemBuilder, onRefresh: onRefresh, emptyState: emptyState, padding: padding);
  }

  Widget buildTabContent({required List<Tab> tabs, required List<Widget> tabViews, TabController? controller}) {
    return AppWidgets.tabScaffold(tabs: tabs, tabViews: tabViews, controller: controller);
  }

  PreferredSizeWidget buildStandardAppBar({List<Widget>? actions}) {
    return AppBar(
      backgroundColor: AppTheme.background, title: Text(screenTitle),
      actions: actions ?? this.actions,
      automaticallyImplyLeading: showBackButton,
    );
  }

  Widget buildTabScaffold({
    required List<Tab> tabs,
    required List<Widget> tabViews,
    TabController? controller,
  }) {
    return buildTabContent(tabs: tabs, tabViews: tabViews, controller: controller);
  }

  Future<void> runAsync(Future<void> Function() operation) async {
    await operation();
  }
}
