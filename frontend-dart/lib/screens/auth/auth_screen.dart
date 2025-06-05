// lib/screens/auth/auth_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_core.dart';
import '../../widgets/app_widgets.dart';
import '../../providers/auth_provider.dart';
import 'package:google_sign_in_web/google_sign_in_web.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import './forgot_password_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override  
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLogin = true;
  bool _isPasswordVisible = false;
  
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final googleSignInPlugin = GoogleSignInPlatform.instance as GoogleSignInPlugin;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(duration: const Duration(milliseconds: 800), vsync: this);
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_fadeController);
    _fadeController.forward();

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
    final success = await Provider.of<AuthProvider>(context, listen: false).googleLoginWeb(account);
    if (success) {
      SnackBarUtils.showSuccess(context, AppStrings.loginSuccessful);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Card(
                  color: AppTheme.surface,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildHeader(),
                          const SizedBox(height: 32),
                          _buildForm(),
                          const SizedBox(height: 32),
                          _buildSubmitButton(),
                          const SizedBox(height: 16),
                          _buildToggleButton(),
                          const SizedBox(height: 16),
                          _buildSocialButtons(),
                          const SizedBox(height: 16),
                          _buildForgotPasswordButton(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: AppTheme.primary,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.music_note, size: 32, color: Colors.black),
        ),
        const SizedBox(height: 16),
        Text(
          _isLogin ? 'Welcome Back' : 'Join ${AppConstants.appName}',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 8),
        Text(
          _isLogin 
            ? 'Sign in to continue your musical journey'
            : 'Create an account to start sharing music',
          style: const TextStyle(color: AppTheme.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Column(
      children: [
        AppTextField(
          controller: _usernameController,
          labelText: AppStrings.username,
          prefixIcon: Icons.person,
          validator: (v) => Validators.required(v, AppStrings.username.toLowerCase()),
        ),
        if (!_isLogin) ...[
          const SizedBox(height: 16),
          AppTextField(
            controller: _emailController,
            labelText: AppStrings.email,
            prefixIcon: Icons.email,
            validator: Validators.email,
          ),
        ],
        const SizedBox(height: 16),
        AppTextField(
          controller: _passwordController,
          labelText: AppStrings.password,
          prefixIcon: Icons.lock,
          obscureText: !_isPasswordVisible,
          validator: Validators.password,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Checkbox(
              value: _isPasswordVisible,
              onChanged: (value) => setState(() => _isPasswordVisible = value ?? false),
              activeColor: AppTheme.primary,
            ),
            const Text('Show password', style: TextStyle(color: AppTheme.textSecondary)),
          ],
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        return AppButton(
          text: _isLogin ? AppStrings.signIn : AppStrings.signUp,
          icon: _isLogin ? Icons.login : Icons.person_add,
          isLoading: auth.isLoading,
          onPressed: _submit,
        );
      },
    );
  }

  Widget _buildToggleButton() {
    return Column(
      children: [
        const Divider(color: AppTheme.surfaceVariant),
        TextButton(
          onPressed: () {
            setState(() {
              _isLogin = !_isLogin;
              _clearForm();
            });
          },
          child: RichText(
            text: TextSpan(
              style: const TextStyle(color: AppTheme.textSecondary),
              children: [
                TextSpan(text: _isLogin ? 'Don\'t have an account? ' : 'Already have an account? '),
                TextSpan(
                  text: _isLogin ? AppStrings.signUp : AppStrings.signIn,
                  style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButtons() {
    return Row(
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildForgotPasswordButton() {
    return Column(
      children: [
        const Divider(color: AppTheme.surfaceVariant),
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ForgotPasswordScreen()),
            );
          },
          child: const Text('Forgot Password?', style: TextStyle(color: AppTheme.textSecondary)),
        ),
      ],
    );
  }

  void _clearForm() {
    _usernameController.clear();
    _emailController.clear();
    _passwordController.clear();
    _isPasswordVisible = false;
    _formKey.currentState?.reset();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    final auth = Provider.of<AuthProvider>(context, listen: false);
    bool success;
    
    try {
      if (_isLogin) {
        success = await auth.login(_usernameController.text.trim(), _passwordController.text);
      } else {
        success = await auth.signup(
          _usernameController.text.trim(), 
          _emailController.text.trim(), 
          _passwordController.text,
        );
      }
      
      if (mounted && success) {
        SnackBarUtils.showSuccess(context, _isLogin ? AppStrings.loginSuccessful : AppStrings.accountCreated);
      } else if (mounted && auth.hasError) {
        SnackBarUtils.showError(context, auth.errorMessage!);
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, 'An unexpected error occurred. Please try again.');
      }
    }
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
      SnackBarUtils.showSuccess(context, AppStrings.loginSuccessful);
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _fadeController.dispose();
    super.dispose();
  }
}
