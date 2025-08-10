import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import '../../core/theme_core.dart';
import '../../core/constants_core.dart';
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
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
      profileProvider.clearMessages(); 
    });
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
                          const Text(
                            'Change Password',
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)
                          ),
                          const SizedBox(height: 24),
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
                              message: profileProvider.successMessage ?? 'Success',
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
                            validator: (v) => v?.isEmpty ?? true ? 'Please enter current password' : null,
                            onFieldSubmitted: kIsWeb ? (_) => _submit() : null,
                          ),
                          const SizedBox(height: 24),
                          AppWidgets.textField(
                            context: context,
                            controller: _newPasswordController,
                            labelText: 'New Password',
                            obscureText: true,
                            validator: AppValidators.password,
                            onFieldSubmitted: kIsWeb ? (_) => _submit() : null,
                          ),
                          const SizedBox(height: 24),
                          AppWidgets.textField(
                            context: context,
                            controller: _confirmPasswordController,
                            labelText: 'Confirm New Password',
                            obscureText: true,
                            validator: (v) => v?.isEmpty ?? true ? 'Please confirm new password' : 
                                      v != _newPasswordController.text ? 'Passwords do not match' : null,
                            onFieldSubmitted: kIsWeb ? (_) => _submit() : null,
                          ), 
                          const SizedBox(height: 24),
                          profileProvider.isLoading
                            ? const CircularProgressIndicator(color: AppTheme.primary)
                            : AppWidgets.primaryButton(context: context, text: 'Submit', onPressed: _submit),
                          const SizedBox(height: 24),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(foregroundColor: Colors.white),
                            child: const Text('Cancel'),
                          ),
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
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    
    if (authProvider.token == null) return;

    bool success = await profileProvider.userPasswordChange(
      authProvider.token, 
      _currentPasswordController.text, 
      _newPasswordController.text
    );
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password changed successfully'), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
