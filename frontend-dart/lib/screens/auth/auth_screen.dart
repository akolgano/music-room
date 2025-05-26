// lib/screens/auth/auth_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../widgets/common_widgets.dart';
import '../../providers/auth_provider.dart';
import 'package:google_sign_in_web/google_sign_in_web.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import './forgot_password_screen.dart';


class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);
  @override State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;

  final googleSignInPlugin = GoogleSignInPlatform.instance as GoogleSignInPlugin;

  @override                                                                 
  void initState() {     
    super.initState();
    if (kIsWeb) {
      _initializeGoogleSignInWeb();
    }
  }

  Future<void> _initializeGoogleSignInWeb() async {
    await googleSignInPlugin.initWithParams(
      SignInInitParameters(
        clientId: dotenv.env['GOOGLE_CLIENT_ID_WEB'],
        scopes: ['email', 'profile', 'openid'],
      ),
    );

    googleSignInPlugin.userDataEvents?.listen((GoogleSignInUserData? account) {
      if (account != null) {
        _googleLoginWeb(account);
      }
    });

  }

  Future<void> _googleLoginWeb(GoogleSignInUserData? account) async {
    bool success = false;
    success = await Provider.of<AuthProvider>(context, listen: false).googleLoginWeb(account);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Login successful'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: Column(
              children: [
                const Icon(Icons.music_note, size: 80, color: AppTheme.primary),
                const SizedBox(height: 20),
                const Text('Music Room', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
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
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Text(_isLogin ? 'Sign In' : 'Create Account', 
                       style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 24),
                  
                  if (authProvider.hasError) ...[
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
                              authProvider.errorMessage ?? 'An error occurred',
                              style: const TextStyle(color: Colors.red, fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  AppTextField(
                    controller: _usernameController,
                    labelText: 'Username',
                    validator: (v) => validateRequired(v, 'username'),
                  ),
                  const SizedBox(height: 16),
                  if (!_isLogin) ...[
                    AppTextField(
                      controller: _emailController,
                      labelText: 'Email',
                      keyboardType: TextInputType.emailAddress,
                      validator: validateEmail,
                    ),
                    const SizedBox(height: 16),
                  ],
                  AppTextField(
                    controller: _passwordController,
                    labelText: 'Password',
                    obscureText: true,
                    validator: (v) => v?.isEmpty ?? true ? 'Please enter password' : 
                              v!.length < 8 ? 'Password must be at least 8 characters' : null,
                  ),
                  const SizedBox(height: 24),
                  
                  authProvider.isLoading
                      ? const CircularProgressIndicator(color: AppTheme.primary)
                      : ElevatedButton(
                          onPressed: _submit,
                          child: Text(_isLogin ? 'SIGN IN' : 'SIGN UP'),
                        ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      setState(() => _isLogin = !_isLogin);
                      authProvider.clearError();
                    },
                    child: Text(_isLogin ? 'Create an account' : 'Already have an account? Sign in'),
                  ),
                  const SizedBox(height: 16),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        if (kIsWeb)
                          googleSignInPlugin.renderButton()
                        else
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _loginWithSocial('Google'),
                              icon: const Icon(Icons.g_mobiledata),
                              label: const Text('GOOGLE'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                side: const BorderSide(color: Colors.white),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(32),
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _loginWithSocial('Facebook'),
                            icon: const Icon(Icons.facebook),
                            label: const Text('FACEBOOK'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: const BorderSide(color: Colors.white),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(32),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                    onPressed: () {
                      Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ForgotPasswordScreen(),
                      ),
                    );
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                    ),
                    child: Text('Forgot Password ?'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
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
          content: Text(_isLogin ? 'Login successful' : 'Account created successfully'),
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
    
  
  void _loginWithSocial(String provider) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    bool success = false;
  
      if (provider == "Facebook") {
        success = await authProvider.facebookLogin();
      }
      else if (provider == "Google") {
        success = await authProvider.googleLoginApp();
      }

      if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Login successful'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      }
  }
}
