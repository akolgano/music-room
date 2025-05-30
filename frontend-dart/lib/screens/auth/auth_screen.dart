// lib/screens/auth/auth_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/app_strings.dart';
import '../../core/constants.dart';
import '../../core/dimensions.dart';
import '../../widgets/common_widgets.dart';
import '../../providers/auth_provider.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override 
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.paddingLarge),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: Column(
              children: [
                Icon(Icons.music_note, 
                     size: AppDimensions.iconXXXLarge, 
                     color: AppTheme.primary),
                const SizedBox(height: AppDimensions.paddingLarge),
                Text(AppStrings.appName, 
                     style: TextStyle(
                       fontSize: AppDimensions.textHeading, 
                       fontWeight: FontWeight.bold, 
                       color: Colors.white)),
                const SizedBox(height: 40),
                _buildForm(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Card(
          color: AppTheme.surface,
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingLarge),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Text(_isLogin ? AppStrings.signIn : AppStrings.createAccount, 
                       style: TextStyle(
                         fontSize: AppDimensions.textTitle, 
                         fontWeight: FontWeight.bold, 
                         color: Colors.white)),
                  const SizedBox(height: AppDimensions.paddingLarge),
                  
                  if (authProvider.hasError) ...[
                    Container(
                      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, 
                                   color: Colors.red, 
                                   size: AppDimensions.iconMedium),
                          const SizedBox(width: AppDimensions.paddingSmall),
                          Expanded(
                            child: Text(
                              authProvider.errorMessage ?? AppStrings.somethingWentWrong,
                              style: TextStyle(
                                color: Colors.red, 
                                fontSize: AppDimensions.textMedium),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDimensions.paddingMedium),
                  ],
                  
                  AppTextField(
                    controller: _usernameController,
                    labelText: AppStrings.username,
                    validator: (v) => _validateRequired(v, AppStrings.username),
                  ),
                  const SizedBox(height: AppDimensions.paddingMedium),
                  
                  if (!_isLogin) ...[
                    AppTextField(
                      controller: _emailController,
                      labelText: AppStrings.email,
                      keyboardType: TextInputType.emailAddress,
                      validator: _validateEmail,
                    ),
                    const SizedBox(height: AppDimensions.paddingMedium),
                  ],
                  
                  AppTextField(
                    controller: _passwordController,
                    labelText: AppStrings.password,
                    obscureText: true,
                    validator: _validatePassword,
                  ),
                  const SizedBox(height: AppDimensions.paddingLarge),
                  
                  authProvider.isLoading
                      ? const CircularProgressIndicator(color: AppTheme.primary)
                      : ElevatedButton(
                          onPressed: _submit,
                          child: Text(_isLogin ? AppStrings.signIn.toUpperCase() : AppStrings.signUp.toUpperCase()),
                        ),
                  const SizedBox(height: AppDimensions.paddingMedium),
                  
                  TextButton(
                    onPressed: () {
                      setState(() => _isLogin = !_isLogin);
                      authProvider.clearError();
                    },
                    child: Text(_isLogin ? AppStrings.createAnAccount : AppStrings.alreadyHaveAccount),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String? _validateRequired(String? value, String fieldName) {
    if (value?.isEmpty ?? true) {
      return '${AppStrings.pleaseEnter} ${fieldName.toLowerCase()}';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value?.isEmpty ?? true) return AppStrings.pleaseEnterEmail;
    if (!RegExp(AppConstants.emailRegexPattern).hasMatch(value!)) {
      return AppStrings.pleaseEnterValidEmail;
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value?.isEmpty ?? true) return AppStrings.pleaseEnterPassword;
    if (value!.length < AppConstants.minPasswordLength) {
      return AppStrings.passwordTooShort;
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    bool success;
    if (_isLogin) {
      success = await authProvider.login(_usernameController.text, _passwordController.text);
    } else {
      success = await authProvider.signup(_usernameController.text, _emailController.text, _passwordController.text);
    }
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isLogin ? AppStrings.loginSuccessful : AppStrings.accountCreated),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
