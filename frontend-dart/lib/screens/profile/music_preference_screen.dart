// lib/screens/profile/music_preference_screen.dart
import 'package:flutter/material.dart';
import '../../core/app_core.dart';
import 'components/music_preference_tab_view.dart';


class MusicPreferenceScreen extends StatefulWidget {
  const MusicPreferenceScreen({Key? key}) : super(key: key);

  @override
  State<MusicPreferenceScreen> createState() => _MusicPreferenceScreenState();
}

class _MusicPreferenceScreenState extends State<MusicPreferenceScreen> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        title: const Text('Music Preference'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primary,
          unselectedLabelColor: Colors.grey,
          tabs: [
            Tab(text: 'Music Preference'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          MusicPreferenceTabView(),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
