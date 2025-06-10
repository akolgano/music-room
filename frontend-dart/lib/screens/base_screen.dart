// lib/screens/base_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/base_provider.dart';
import '../core/app_core.dart';
import '../utils/dialog_utils.dart';
import '../widgets/common_widgets.dart';

abstract class BaseScreen<T extends StatefulWidget> extends State<T> {
  AuthProvider get auth => Provider.of<AuthProvider>(context, listen: false);
  
  String get screenTitle;
  Widget buildContent();
  
  bool get showDrawer => true;
  List<Widget> get actions => [];
  Widget? get floatingActionButton => null;
  bool get showRefreshAction => false;
  VoidCallback? get onRefresh => null;
  
  bool get isLoading => false;
  bool get hasError => false;
  String? get errorMessage => null;

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
    leading: showDrawer ? null : _buildCustomLeading(),
    actions: _buildActions(),
  );

  PreferredSizeWidget buildStandardAppBar({
    String? title,
    List<Widget>? actions,
    Widget? leading,
    bool automaticallyImplyLeading = true,
  }) {
    return AppBar(
      backgroundColor: AppTheme.background,
      title: Text(title ?? screenTitle),
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      actions: actions ?? this.actions,
    );
  }

  Widget buildTabContent({
    required List<Tab> tabs,
    required List<Widget> tabViews,
    TabController? controller,
  }) {
    return DefaultTabController(
      length: tabs.length,
      child: Column(
        children: [
          TabBar(
            controller: controller,
            labelColor: AppTheme.primary,
            unselectedLabelColor: Colors.grey,
            tabs: tabs,
          ),
          Expanded(
            child: TabBarView(
              controller: controller,
              children: tabViews,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildTabScaffold({
    required List<Tab> tabs,
    required List<Widget> tabViews,
    TabController? controller,
  }) {
    return DefaultTabController(
      length: tabs.length,
      child: Column(
        children: [
          TabBar(
            controller: controller,
            labelColor: AppTheme.primary,
            unselectedLabelColor: Colors.grey,
            tabs: tabs,
          ),
          Expanded(
            child: TabBarView(
              controller: controller,
              children: tabViews,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildConsumerContent<P extends ChangeNotifier>({
    required Widget Function(BuildContext, P) builder,
    Widget Function(String)? errorBuilder,
    Widget Function()? loadingBuilder,
    Widget Function()? emptyBuilder,
  }) {
    return Consumer<P>(
      builder: (context, provider, _) {
        if (provider is BaseProvider) {
          if (provider.isLoading) {
            return loadingBuilder?.call() ?? buildLoadingState();
          }
          if (provider.hasError) {
            return errorBuilder?.call(provider.errorMessage!) ?? 
                   buildErrorState(message: provider.errorMessage!);
          }
        }
        return builder(context, provider);
      },
    );
  }

  Widget buildListContent<I>({
    required List<I> items,
    required Widget Function(I, int) itemBuilder,
    required Future<void> Function() onRefresh,
    Widget? emptyState,
    Widget? header,
    EdgeInsets? padding,
    String Function(I)? searchFilter,
    String? searchHint,
  }) {
    Widget content;
    
    if (searchFilter != null) {
      content = _buildSearchableList(
        items: items,
        itemBuilder: itemBuilder,
        searchFilter: searchFilter,
        searchHint: searchHint,
        onRefresh: onRefresh,
        emptyState: emptyState,
        padding: padding,
      );
    } else {
      content = _buildSimpleList(
        items: items,
        itemBuilder: itemBuilder,
        onRefresh: onRefresh,
        emptyState: emptyState,
        padding: padding,
      );
    }

    if (header != null) {
      return Column(
        children: [header, Expanded(child: content)],
      );
    }
    return content;
  }

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
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: emptyState,
          ),
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

  Widget buildSearchableList<I>({
    required List<I> items,
    required Widget Function(I, int) itemBuilder,
    required String Function(I) searchFilter,
    String? searchHint,
    Widget? emptyState,
    Widget? noResultsState,
    EdgeInsets? padding,
    Future<void> Function()? onRefresh,
  }) {
    return StatefulBuilder(
      builder: (context, setState) {
        final searchController = TextEditingController();
        List<I> filteredItems = items;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: AppTextField(
                controller: searchController,
                labelText: 'Search',
                hintText: searchHint ?? 'Start typing to search...',
                prefixIcon: Icons.search,
                onChanged: (query) {
                  setState(() {
                    filteredItems = query.isEmpty ? items : items
                        .where((item) => searchFilter(item)
                            .toLowerCase()
                            .contains(query.toLowerCase()))
                        .toList();
                  });
                },
              ),
            ),
            Expanded(
              child: _buildListView(
                items: filteredItems,
                originalItems: items,
                itemBuilder: itemBuilder,
                emptyState: emptyState,
                noResultsState: noResultsState,
                padding: padding,
                onRefresh: onRefresh,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget buildFormContent({
    required List<Widget> children,
    String? title,
    IconData? titleIcon,
    VoidCallback? onSubmit,
    String? submitText,
    bool isLoading = false,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: AppTheme.buildFormCard(
        title: title,
        titleIcon: titleIcon,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ...children,
            if (onSubmit != null) ...[
              const SizedBox(height: 24),
              AppTheme.buildPrimaryButton(
                text: submitText ?? 'Submit',
                onPressed: onSubmit,
                isLoading: isLoading,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget buildLoadingState({String? message}) => CommonWidgets.loadingWidget(message);
  
  Widget buildErrorState({
    required String message,
    VoidCallback? onRetry,
    String? retryText,
  }) => CommonWidgets.errorState(
    message: message,
    onRetry: onRetry,
    retryText: retryText,
  );

  Widget buildEmptyState({
    required IconData icon,
    required String title,
    String? subtitle,
    String? buttonText,
    VoidCallback? onButtonPressed,
  }) => CommonWidgets.emptyState(
    icon: icon,
    title: title,
    subtitle: subtitle,
    buttonText: buttonText,
    onButtonPressed: onButtonPressed,
  );

  Widget buildInfoBanner({
    required String title,
    required String message,
    required IconData icon,
    Color color = AppTheme.primary,
    VoidCallback? onAction,
    String? actionText,
  }) {
    return InfoBanner(
      title: title,
      message: message,
      icon: icon,
      color: color,
      onAction: onAction,
      actionText: actionText,
    );
  }

  Widget _buildSimpleList<I>({
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
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: emptyState,
          ),
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

  Widget _buildSearchableList<I>({
    required List<I> items,
    required Widget Function(I, int) itemBuilder,
    required String Function(I) searchFilter,
    required Future<void> Function() onRefresh,
    String? searchHint,
    Widget? emptyState,
    EdgeInsets? padding,
  }) {
    return StatefulBuilder(
      builder: (context, setState) {
        final searchController = TextEditingController();
        List<I> filteredItems = items;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: AppTextField(
                controller: searchController,
                labelText: 'Search',
                hintText: searchHint ?? 'Start typing to search...',
                prefixIcon: Icons.search,
                onChanged: (query) {
                  setState(() {
                    filteredItems = query.isEmpty ? items : items
                        .where((item) => searchFilter(item)
                            .toLowerCase()
                            .contains(query.toLowerCase()))
                        .toList();
                  });
                },
              ),
            ),
            Expanded(
              child: _buildSimpleList(
                items: filteredItems,
                itemBuilder: itemBuilder,
                onRefresh: onRefresh,
                emptyState: items.isEmpty ? emptyState : 
                           (filteredItems.isEmpty ? _buildNoResults() : null),
                padding: EdgeInsets.symmetric(horizontal: padding?.horizontal ?? 16),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildListView<I>({
    required List<I> items,
    required List<I> originalItems,
    required Widget Function(I, int) itemBuilder,
    Widget? emptyState,
    Widget? noResultsState,
    EdgeInsets? padding,
    Future<void> Function()? onRefresh,
  }) {
    if (originalItems.isEmpty && emptyState != null) return emptyState;
    if (items.isEmpty && noResultsState != null) return noResultsState;
    if (items.isEmpty) return const Center(child: Text('No results found', style: TextStyle(color: Colors.grey)));

    final listView = ListView.builder(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 16),
      itemCount: items.length,
      itemBuilder: (context, index) => itemBuilder(items[index], index),
    );

    return onRefresh != null ? RefreshIndicator(onRefresh: onRefresh, color: AppTheme.primary, child: listView) : listView;
  }

  Widget _buildNoResults() => const Center(
    child: Text('No results found', style: TextStyle(color: Colors.grey)),
  );

  List<Widget> _buildActions() {
    final actionList = <Widget>[];
    if (showRefreshAction && onRefresh != null) {
      actionList.add(IconButton(
        icon: const Icon(Icons.refresh),
        onPressed: onRefresh,
        tooltip: 'Refresh',
      ));
    }
    actionList.addAll(actions);
    return actionList;
  }

  Widget? _buildCustomLeading() => null;

  Widget _buildDrawer() {
    return Drawer(
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
          ..._buildDrawerItems(),
        ],
      ),
    );
  }

  List<Widget> _buildDrawerItems() => [
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
  ];

  Widget _drawerItem(IconData icon, String title, String route) => ListTile(
    leading: Icon(icon, color: Colors.white),
    title: Text(title, style: const TextStyle(color: Colors.white)),
    onTap: () {
      Navigator.pop(context);
      Navigator.pushNamed(context, route);
    },
  );

  void navigateTo(String route, {Object? arguments}) => 
      Navigator.pushNamed(context, route, arguments: arguments);
  void navigateAndReplace(String route, {Object? arguments}) => 
      Navigator.pushReplacementNamed(context, route, arguments: arguments);
  void navigateBack([dynamic result]) => Navigator.pop(context, result);
  void navigateToHome() => navigateTo(AppRoutes.home);
  void navigateToFriends() => navigateTo(AppRoutes.friends);
  void navigateToTrackSearch([String? playlistId]) => 
      navigateTo(AppRoutes.trackSearch, arguments: playlistId);

  Future<bool> showConfirmDialog(String title, String message, {bool isDangerous = false}) async =>
      await DialogUtils.showConfirmDialog(context, title: title, message: message, isDangerous: isDangerous) ?? false;
  Future<String?> showTextInputDialog(String title, {String? initialValue, String? hintText}) async =>
      await DialogUtils.showTextInputDialog(context, title: title, initialValue: initialValue, hintText: hintText);
  void showFeatureComingSoon([String? feature]) => DialogUtils.showFeatureComingSoon(context, feature);

  void showSuccess(String message) => _showSnackBar(message, Colors.green);
  void showError(String message) => _showSnackBar(message, AppTheme.error);
  void showInfo(String message) => _showSnackBar(message, Colors.blue);

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

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

  T getProvider<T>({bool listen = false}) => Provider.of<T>(context, listen: listen);
}
