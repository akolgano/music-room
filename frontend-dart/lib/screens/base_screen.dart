// lib/screens/base_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../core/app_core.dart';
import '../utils/snackbar_utils.dart';
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
  
  PreferredSizeWidget? buildAppBar() => AppBar(
    backgroundColor: AppTheme.background,
    title: Text(screenTitle),
    leading: showDrawer ? null : _buildCustomLeading(),
    actions: _buildActions(),
  );

  Widget? _buildCustomLeading() => null;

  List<Widget> _buildActions() {
    final actionList = <Widget>[];
    
    if (showRefreshAction && onRefresh != null) {
      actionList.add(
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: onRefresh,
          tooltip: 'Refresh',
        ),
      );
    }
    
    actionList.addAll(actions);
    return actionList;
  }

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

  Widget buildStandardAppBar({
    String? title,
    List<Widget>? actions,
    bool showRefresh = false,
    VoidCallback? onRefresh,
    Widget? leading,
  }) {
    final appBarActions = <Widget>[];
    
    if (showRefresh && onRefresh != null) {
      appBarActions.add(
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: onRefresh,
          tooltip: 'Refresh',
        ),
      );
    }
    
    if (actions != null) {
      appBarActions.addAll(actions);
    }

    return AppBar(
      backgroundColor: AppTheme.background,
      title: Text(title ?? screenTitle),
      leading: leading,
      actions: appBarActions.isNotEmpty ? appBarActions : null,
    );
  }

  Widget buildTabScaffold({
    required List<Tab> tabs,
    required List<Widget> tabViews,
    List<Widget>? actions,
    String? title,
    TabController? controller,
  }) {
    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          backgroundColor: AppTheme.background,
          title: Text(title ?? screenTitle),
          actions: actions,
          bottom: TabBar(
            controller: controller,
            labelColor: AppTheme.primary,
            unselectedLabelColor: Colors.grey,
            tabs: tabs,
          ),
        ),
        drawer: showDrawer ? _buildDrawer() : null,
        body: TabBarView(
          controller: controller,
          children: tabViews,
        ),
        floatingActionButton: floatingActionButton,
      ),
    );
  }

  Widget buildListWithRefresh<T>({
    required List<T> items,
    required Widget Function(T item, int index) itemBuilder,
    required Future<void> Function() onRefresh,
    Widget? emptyState,
    EdgeInsets? padding,
    bool shrinkWrap = false,
    ScrollPhysics? physics,
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
        shrinkWrap: shrinkWrap,
        physics: physics,
        itemBuilder: (context, index) => itemBuilder(items[index], index),
      ),
    );
  }

  Widget buildGridWithRefresh<T>({
    required List<T> items,
    required Widget Function(T item, int index) itemBuilder,
    required Future<void> Function() onRefresh,
    required int crossAxisCount,
    Widget? emptyState,
    EdgeInsets? padding,
    double mainAxisSpacing = 8,
    double crossAxisSpacing = 8,
    double childAspectRatio = 1,
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
      child: GridView.builder(
        padding: padding ?? const EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: mainAxisSpacing,
          crossAxisSpacing: crossAxisSpacing,
          childAspectRatio: childAspectRatio,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) => itemBuilder(items[index], index),
      ),
    );
  }

  Widget buildSearchableList<T>({
    required List<T> items,
    required Widget Function(T item, int index) itemBuilder,
    required String Function(T item) searchFilter,
    String? searchHint,
    Widget? emptyState,
    Widget? noResultsState,
    EdgeInsets? padding,
    Future<void> Function()? onRefresh,
  }) {
    return StatefulBuilder(
      builder: (context, setState) {
        final searchController = TextEditingController();
        List<T> filteredItems = items;

        void filterItems(String query) {
          setState(() {
            filteredItems = query.isEmpty
                ? items
                : items
                    .where((item) => searchFilter(item)
                        .toLowerCase()
                        .contains(query.toLowerCase()))
                    .toList();
          });
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: AppTextField(
                controller: searchController,
                labelText: 'Search',
                hintText: searchHint ?? 'Start typing to search...',
                prefixIcon: Icons.search,
                onChanged: filterItems,
              ),
            ),
            Expanded(
              child: _buildFilteredList(
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

  Widget _buildFilteredList<T>({
    required List<T> items,
    required List<T> originalItems,
    required Widget Function(T item, int index) itemBuilder,
    Widget? emptyState,
    Widget? noResultsState,
    EdgeInsets? padding,
    Future<void> Function()? onRefresh,
  }) {
    if (originalItems.isEmpty && emptyState != null) {
      return emptyState;
    }

    if (items.isEmpty && noResultsState != null) {
      return noResultsState;
    }

    if (items.isEmpty) {
      return const Center(
        child: Text(
          'No results found',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    final listView = ListView.builder(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 16),
      itemCount: items.length,
      itemBuilder: (context, index) => itemBuilder(items[index], index),
    );

    if (onRefresh != null) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        color: AppTheme.primary,
        child: listView,
      );
    }

    return listView;
  }

  Widget buildLoadingState({String? message}) {
    return CommonWidgets.loadingWidget(message);
  }

  Widget buildErrorState({
    required String message,
    VoidCallback? onRetry,
    String? retryText,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(retryText ?? 'Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.black,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget buildSuccessState({
    required String title,
    required String message,
    VoidCallback? onContinue,
    String? continueText,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, size: 64, color: Colors.green),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            if (onContinue != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: Text(continueText ?? 'Continue'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    final auth = Provider.of<AuthProvider>(context);
    
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

  void showSuccess(String message) => SnackBarUtils.showSuccess(context, message);
  void showError(String message) => SnackBarUtils.showError(context, message);
  void showInfo(String message) => SnackBarUtils.showInfo(context, message);

  Future<T?> runAsync<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } catch (e) {
      showError(e.toString());
      return null;
    }
  }

  Future<void> runAsyncAction(
    Future<void> Function() operation, {
    String? loadingMessage,
    String? successMessage,
    String? errorMessage,
  }) async {
    try {
      if (loadingMessage != null) {
      }
      
      await operation();
      
      if (successMessage != null) {
        showSuccess(successMessage);
      }
    } catch (e) {
      showError(errorMessage ?? e.toString());
    }
  }

  void navigateTo(String route, {Object? arguments}) {
    Navigator.pushNamed(context, route, arguments: arguments);
  }

  void navigateAndReplace(String route, {Object? arguments}) {
    Navigator.pushReplacementNamed(context, route, arguments: arguments);
  }

  void navigateBack([dynamic result]) {
    Navigator.pop(context, result);
  }

  bool canNavigateBack() {
    return Navigator.canPop(context);
  }

  void showSnackBarMessage(String message, {bool isError = false}) {
    if (isError) {
      showError(message);
    } else {
      showSuccess(message);
    }
  }
}
