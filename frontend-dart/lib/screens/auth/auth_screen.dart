// lib/screens/auth/auth_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_core.dart';
import '../../widgets/common_widgets.dart';
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
    _fadeController = AnimationController(duration: AppDurations.longDelay, vsync: this);
    _fadeAnimation = AppAnimations.fadeIn.animate(_fadeController);
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
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.googleLoginWeb(account);
    if (success && mounted) {
      _showSuccessAndNavigate(AppStrings.loginSuccessful);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: AppSizes.screenPadding,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Consumer<AuthProvider>(
                  builder: (context, authProvider, child) => Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 32),
                        if (authProvider.hasError) 
                          ErrorBanner(message: authProvider.errorMessage!),
                        _buildFormCard(authProvider),
                        const SizedBox(height: 24),
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
    );
  }

  Widget _buildHeader() {
    return AppTheme.buildHeaderCard(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.music_note, size: 32, color: AppTheme.primary),
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
            style: const TextStyle(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard(AuthProvider authProvider) {
    return AppTheme.buildFormCard(
      title: _isLogin ? 'Sign In' : 'Create Account',
      titleIcon: _isLogin ? Icons.login : Icons.person_add,
      child: Column(
        children: [
          AppTextField(
            controller: _usernameController,
            labelText: AppStrings.username,
            prefixIcon: Icons.person,
            validator: Validators.username,
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
          const SizedBox(height: 24),
          AppTheme.buildPrimaryButton(
            text: _isLogin ? AppStrings.signIn : AppStrings.signUp,
            onPressed: _submit,
            icon: _isLogin ? Icons.login : Icons.person_add,
            isLoading: authProvider.isLoading,
          ),
          const SizedBox(height: 16),
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
      ),
    );
  }

  Widget _buildSocialButtons() {
    return AppTheme.buildStandardCard(
      child: Column(
        children: [
          const Text(
            'Or continue with',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (kIsWeb)
                googleSignInPlugin.renderButton()
              else
                Expanded(
                  child: AppButton(
                    text: 'GOOGLE',
                    onPressed: () => _loginWithSocial('Google'),
                    icon: Icons.g_mobiledata,
                    isOutlined: true,
                    fullWidth: true,
                  ),
                ),
              const SizedBox(width: 16),
              Expanded(
                child: AppButton(
                  text: 'FACEBOOK',
                  onPressed: () => _loginWithSocial('Facebook'),
                  icon: Icons.facebook,
                  isOutlined: true,
                  fullWidth: true,
                ),
              ),
            ],
          ),
        ],
      ),
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
              MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
            );
          },
          child: const Text(
            'Forgot Password?',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
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
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    bool success;
    
    try {
      if (_isLogin) {
        success = await authProvider.login(_usernameController.text.trim(), _passwordController.text);
      } else {
        success = await authProvider.signup(
          _usernameController.text.trim(), 
          _emailController.text.trim(), 
          _passwordController.text,
        );
      }
      
      if (mounted && success) {
        _showSuccessAndNavigate(_isLogin ? AppStrings.loginSuccessful : AppStrings.accountCreated);
      }
    } catch (e) {
    }
  }

  void _loginWithSocial(String provider) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    bool success = false;
  
    if (provider == "Facebook") {
      success = await authProvider.facebookLogin();
    } else if (provider == "Google") {
      success = await authProvider.googleLoginApp();
    }

    if (success && mounted) {
      _showSuccessAndNavigate(AppStrings.loginSuccessful);
    }
  }

  void _showSuccessAndNavigate(String message) {
    if (mounted) {
      CommonWidgets.showSnackBar(context, message);
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
