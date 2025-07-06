// lib/screens/profile/user_password_change_screen.dart
import 'package:flutter/material.dart';
import '../../core/core.dart';
import '../../widgets/app_widgets.dart';
import '../../providers/profile_provider.dart';
import '../base_screen.dart';

class UserPasswordChangeScreen extends StatefulWidget {
  const UserPasswordChangeScreen({Key? key}) : super(key: key);
  
  @override
  State<UserPasswordChangeScreen> createState() => _UserPasswordChangeScreenState();
}

class _UserPasswordChangeScreenState extends BaseScreen<UserPasswordChangeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  
  @override
  String get screenTitle => 'Change Password';
  
  @override
  bool get showMiniPlayer => false;
  
  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }
  
  @override
  Widget buildContent() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 450),
          child: AppTheme.buildFormCard(
            title: 'Change Password',
            titleIcon: Icons.password,
            child: buildConsumerContent<ProfileProvider>(
              builder: (context, profileProvider) {
                return Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      if (profileProvider.hasError) ...[
                        AppWidgets.errorBanner(
                          message: profileProvider.errorMessage ?? 'An error occurred',
                          onDismiss: () => profileProvider.clearMessages(),
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (profileProvider.hasSuccess) ...[
                        AppWidgets.infoBanner(
                          title: 'Success',
                          message: profileProvider.successMessage ?? 'Password changed successfully',
                          icon: Icons.check_circle,
                          color: Colors.green,
                        ),
                        const SizedBox(height: 16),
                      ],
                      AppWidgets.textField(
                        context: context,
                        controller: _currentPasswordController,
                        labelText: 'Current Password',
                        obscureText: true,
                        validator: AppValidators.password,
                      ),
                      const SizedBox(height: 16),
                      AppWidgets.textField(
                        context: context,
                        controller: _newPasswordController,
                        labelText: 'New Password',
                        obscureText: true,
                        validator: AppValidators.password,
                      ),
                      const SizedBox(height: 24),
                      AppWidgets.primaryButton(
                        context: context,
                        text: 'Change Password',
                        onPressed: profileProvider.isLoading ? null : _submit,
                        isLoading: profileProvider.isLoading,
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: navigateBack,
                        style: TextButton.styleFrom(foregroundColor: Colors.white),
                        child: const Text('Cancel'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
  
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await runAsyncAction(
      () async {
        final profileProvider = getProvider<ProfileProvider>();
        final success = await profileProvider.userPasswordChange(
          auth.token,
          _currentPasswordController.text,
          _newPasswordController.text,
        );
        if (success) {
          _currentPasswordController.clear();
          _newPasswordController.clear();
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) navigateBack();
          });
        }
      },
      successMessage: 'Password changed successfully!',
      errorMessage: 'Failed to change password',
    );
  }
}
