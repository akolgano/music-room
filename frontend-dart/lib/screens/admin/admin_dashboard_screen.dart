import 'package:flutter/material.dart';
import '../../core/theme_utils.dart';
import 'admin_webview_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Django Routes',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Access Django admin interface and API endpoints directly from the app.',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 32),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2,
                children: [
                  _buildRouteCard(
                    context,
                    title: 'Django Admin',
                    subtitle: 'Admin interface',
                    icon: Icons.admin_panel_settings,
                    color: Colors.red,
                    route: '/admin/',
                  ),
                  _buildRouteCard(
                    context,
                    title: 'API Root',
                    subtitle: 'Browse API endpoints',
                    icon: Icons.api,
                    color: Colors.blue,
                    route: '/api/',
                  ),
                  _buildRouteCard(
                    context,
                    title: 'API Users',
                    subtitle: 'User management API',
                    icon: Icons.people,
                    color: Colors.green,
                    route: '/api/users/',
                  ),
                  _buildRouteCard(
                    context,
                    title: 'API Playlists',
                    subtitle: 'Playlist management',
                    icon: Icons.playlist_play,
                    color: Colors.purple,
                    route: '/api/playlists/',
                  ),
                  _buildRouteCard(
                    context,
                    title: 'API Tracks',
                    subtitle: 'Track management',
                    icon: Icons.music_note,
                    color: Colors.orange,
                    route: '/api/tracks/',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String route,
  }) {
    return Card(
      color: AppTheme.surface,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AdminWebViewScreen(
                routePath: route,
                title: title,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: color,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}