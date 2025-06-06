// lib/screens/base_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../core/app_core.dart';
import '../utils/snackbar_utils.dart';

abstract class BaseScreen<T extends StatefulWidget> extends State<T> {
  AuthProvider get auth => Provider.of<AuthProvider>(context, listen: false);
  
  String get screenTitle;
  Widget buildContent();
  
  bool get showDrawer => true;
  List<Widget> get actions => [];
  Widget? get floatingActionButton => null;
  
  PreferredSizeWidget? buildAppBar() => AppBar(
    backgroundColor: AppTheme.background,
    title: Text(screenTitle),
    leading: showDrawer ? null : _buildCustomLeading(),
    actions: actions,
  );

  Widget? _buildCustomLeading() => null;

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

  Future<T?> runAsync<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } catch (e) {
      showError(e.toString());
      return null;
    }
  }
}
