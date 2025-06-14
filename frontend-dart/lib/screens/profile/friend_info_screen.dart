// lib/screens/profile/friend_info_screen.dart
import 'package:flutter/material.dart';
import '../../core/app_core.dart';
import 'components/friend_info_tab_view.dart';


class FriendInfoScreen extends StatefulWidget {
  const FriendInfoScreen({Key? key}) : super(key: key);

  @override
  State<FriendInfoScreen> createState() => _FriendInfoScreenState();
}

class _FriendInfoScreenState extends State<FriendInfoScreen> with TickerProviderStateMixin {
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
        title: const Text('Friend Info'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primary,
          unselectedLabelColor: Colors.grey,
          tabs: [
            Tab(text: 'Friend Info'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          FriendInfoTabView(),
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
