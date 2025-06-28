// lib/screens/profile/profile_info_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/core.dart';
import '../../providers/profile_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_widgets.dart';

class ProfileInfoScreen extends StatefulWidget {
  const ProfileInfoScreen({Key? key}) : super(key: key);

  @override
  State<ProfileInfoScreen> createState() => _ProfileInfoScreenState();
}

class _ProfileInfoScreenState extends State<ProfileInfoScreen> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        title: const Text('Profile Information'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primary,
          unselectedLabelColor: Colors.grey,
          isScrollable: true,
          tabs: const [Tab(text: 'Public'), Tab(text: 'Private'), Tab(text: 'Friends'), Tab(text: 'Music')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [const _PublicInfoTab(), const _PrivateInfoTab(), const _FriendInfoTab(), const _MusicPreferenceTab()],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

class _PrivateInfoTab extends StatefulWidget {
  const _PrivateInfoTab();

  @override
  State<_PrivateInfoTab> createState() => _PrivateInfoTabState();
}

class _PrivateInfoTabState extends State<_PrivateInfoTab> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileProvider>(
      builder: (context, profileProvider, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Card(
              color: AppTheme.surface,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    AppWidgets.textField(
                      controller: _phoneController,
                      labelText: 'Phone Number',
                      validator: (value) => AppValidators.phoneNumber(value, false), 
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PublicInfoTab extends StatelessWidget {
  const _PublicInfoTab();
  @override
  Widget build(BuildContext context) => const Center(child: Text('Public Info Tab', style: TextStyle(color: Colors.white)));
}

class _FriendInfoTab extends StatelessWidget {
  const _FriendInfoTab();
  @override
  Widget build(BuildContext context) => const Center(child: Text('Friend Info Tab', style: TextStyle(color: Colors.white)));
}

class _MusicPreferenceTab extends StatelessWidget {
  const _MusicPreferenceTab();
  @override
  Widget build(BuildContext context) => const Center(child: Text('Music Preferences Tab', style: TextStyle(color: Colors.white)));
}
