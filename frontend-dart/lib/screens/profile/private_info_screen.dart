// lib/screens/profile/private_info_screen.dart
import 'package:flutter/material.dart';
import '../../core/app_core.dart';
import 'components/private_info_tab_view.dart';


class PrivateInfoScreen extends StatefulWidget {
  const PrivateInfoScreen({Key? key}) : super(key: key);

  @override
  State<PrivateInfoScreen> createState() => _PrivateInfoScreenState();
}

class _PrivateInfoScreenState extends State<PrivateInfoScreen> with TickerProviderStateMixin {
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
        title: const Text('Private Info'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primary,
          unselectedLabelColor: Colors.grey,
          tabs: [
            Tab(text: 'Private Info'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          PrivateInfoTabView(),
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
