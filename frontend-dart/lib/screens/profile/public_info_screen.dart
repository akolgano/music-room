// lib/screens/profile/public_info_screen.dart
import 'package:flutter/material.dart';
import '../../core/app_core.dart';
import 'components/public_avatar_tab_view.dart';
import 'components/public_basic_tab_view.dart';
import 'components/public_bio_tab_view.dart';


class PublicInfoScreen extends StatefulWidget {
  const PublicInfoScreen({Key? key}) : super(key: key);

  @override
  State<PublicInfoScreen> createState() => _PublicInfoScreenState();
}

class _PublicInfoScreenState extends State<PublicInfoScreen> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        title: const Text('Public Info'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primary,
          unselectedLabelColor: Colors.grey,
          tabs: [
            Tab(text: 'Avatar'),
            Tab(text: 'Basic'),
            Tab(text: 'Bio'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          PublicAvatarTabView(),
          PublicBasicTabView(),
          PublicBioTabView(),
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
