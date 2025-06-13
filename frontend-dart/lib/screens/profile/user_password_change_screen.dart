// lib/screens/profile/user_password_change_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_core.dart';
import '../../widgets/common_widgets.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';

class UserPasswordChangeScreen extends StatefulWidget {
  const UserPasswordChangeScreen({Key? key}) : super(key: key);

  @override 
  State<UserPasswordChangeScreen> createState() => _UserPasswordChangeScreenState();
}

class _UserPasswordChangeScreenState extends State<UserPasswordChangeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    profileProvider.clearError();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        title: const Text('Change Password'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: Card(
              color: AppTheme.surface,
              child: Padding(
                padding: const EdgeInsets.all(24),
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
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.red.withOpacity(0.3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline, color: Colors.red, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      profileProvider.errorMessage ?? 'An error occurred',
                                      style: const TextStyle(color: Colors.red, fontSize: 14),
                                    ),
                                  ),  
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          FormComponents.textField(
                            controller: _currentPasswordController,
                            labelText: 'Current Password',
                            obscureText: true,
                            validator: (v) => v?.isEmpty ?? true ? 'Please enter current password' : 
                                      v!.length < 8 ? 'Password must be at least 8 characters' : null,
                          ),
                          const SizedBox(height: 24),
                          FormComponents.textField(
                            controller: _newPasswordController,
                            labelText: 'New Password',
                            obscureText: true,
                            validator: (v) => v?.isEmpty ?? true ? 'Please enter new password' : 
                                      v!.length < 8 ? 'Password must be at least 8 characters' : null,
                          ), 
                          const SizedBox(height: 24),
                          profileProvider.isLoading
                            ? const CircularProgressIndicator(color: AppTheme.primary)
                            : ElevatedButton(
                                onPressed: _submit,
                                child: const Text('Submit'),
                              ),
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

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password changed successfully'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }
}
