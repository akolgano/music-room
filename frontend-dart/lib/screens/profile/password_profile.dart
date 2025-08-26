import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import '../../core/theme_core.dart';
import '../../core/provider_core.dart';
import '../../widgets/app_widgets.dart';
import '../../providers/auth_providers.dart';
import '../../providers/profile_providers.dart';

class UserPasswordChangeScreen extends StatefulWidget {
  const UserPasswordChangeScreen({super.key});
  
  @override 
  State<UserPasswordChangeScreen> createState() => _UserPasswordChangeScreenState();
}

class _UserPasswordChangeScreenState extends State<UserPasswordChangeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController(), _newPasswordController = TextEditingController(), _confirmPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<ProfileProvider>().clearMessages());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(backgroundColor: AppTheme.background, title: const Text('Change Password')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(5),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: Card(
              color: AppTheme.surface,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Form(
                  key: _formKey,
                  child: Consumer<ProfileProvider>(
                    builder: (context, profileProvider, child) {
                      return Column(
                        children: [
                          const Text('Change Password', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                          const SizedBox(height: 24),
                          if (profileProvider.hasError)
                            Padding(padding: const EdgeInsets.only(bottom: 16), child: AppWidgets.errorBanner(message: profileProvider.errorMessage ?? 'An error occurred', onDismiss: profileProvider.clearMessages)),
                          if (profileProvider.hasSuccess)
                            Padding(padding: const EdgeInsets.only(bottom: 16), child: AppWidgets.infoBanner(title: 'Success', message: profileProvider.successMessage ?? 'Success', icon: Icons.check_circle, color: Colors.green)),
                          ...[
                            ('Current Password', _currentPasswordController, (v) => v?.isEmpty ?? true ? 'Please enter current password' : null),
                            ('New Password', _newPasswordController, AppValidators.password),
                            ('Confirm New Password', _confirmPasswordController, (v) => v?.isEmpty ?? true ? 'Please confirm new password' : v != _newPasswordController.text ? 'Passwords do not match' : null),
                          ].map((field) => Padding(
                            padding: const EdgeInsets.only(bottom: 24),
                            child: AppWidgets.textField(
                              context: context,
                              controller: field.$2,
                              labelText: field.$1,
                              obscureText: true,
                              validator: field.$3 as String? Function(String?)?,
                              onFieldSubmitted: kIsWeb ? (_) => _submit() : null,
                            ),
                          )), 
                          profileProvider.isLoading ? const CircularProgressIndicator(color: AppTheme.primary) : AppWidgets.primaryButton(context: context, text: 'Submit', onPressed: _submit),
                          const SizedBox(height: 24),
                          TextButton(onPressed: () => Navigator.pop(context), style: TextButton.styleFrom(foregroundColor: Colors.white), child: const Text('Cancel')),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    if (auth.token == null) return;
    if (await context.read<ProfileProvider>().userPasswordChange(auth.token, _currentPasswordController.text, _newPasswordController.text) && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password changed successfully'), backgroundColor: Colors.green));
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    for (final c in [_currentPasswordController, _newPasswordController, _confirmPasswordController]) {
      c.dispose();
    }
    super.dispose();
  }
}
