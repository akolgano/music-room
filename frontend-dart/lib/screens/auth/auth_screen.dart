// lib/screens/auth/auth_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/core.dart';
import '../../widgets/app_widgets.dart';
import '../base_screen.dart';
import 'signup_with_otp_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends BaseScreen<AuthScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLogin = true;
  bool _isLoading = false;
  late AnimationController _rotationController;

  @override
  String get screenTitle => 'Authentication';

  @override
  bool get showBackButton => false;

  @override
  bool get showMiniPlayer => false;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(duration: const Duration(seconds: 2), vsync: this)..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget buildContent() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 32),
              _buildForm(),
              const SizedBox(height: 24),
              _buildSocialButtons(),
              const SizedBox(height: 16),
              _buildModeToggle(),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(child: buildContent()),
    );
  }

  Widget _buildHeader() => AppTheme.buildFormCard(
    title: _isLogin ? 'Welcome Back' : 'Join Music Room',
    titleIcon: Icons.music_note,
    child: Column(
      children: [
        const Icon(Icons.music_note, size: 40, color: AppTheme.primary),
        const SizedBox(height: 16),
        Text(
          _isLogin ? 'Sign in to continue your musical journey' : 'Create an account to start sharing music',
          style: const TextStyle(color: Colors.white70),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );

  Widget _buildForm() => AppTheme.buildFormCard(
    title: _isLogin ? 'Sign In' : 'Create Account',
    child: Form(
      key: _formKey,
      child: Column(
        children: [
          AppWidgets.textField(
            controller: _usernameController, 
            labelText: 'Username', 
            prefixIcon: Icons.person, 
            validator: AppValidators.username
          ),
          if (!_isLogin) ...[
            const SizedBox(height: 16),
            AppWidgets.textField(
              controller: _emailController,
              labelText: 'Email',
              prefixIcon: Icons.email,
              validator: AppValidators.email,
            ),
          ],
          const SizedBox(height: 16),
          AppWidgets.textField(
            controller: _passwordController,
            labelText: 'Password',
            prefixIcon: Icons.lock,
            obscureText: true,
            validator: AppValidators.password,
          ),
          const SizedBox(height: 24),
          AppWidgets.primaryButton(
            text: _isLogin ? 'Sign In' : 'Sign Up',
            onPressed: _isLoading ? null : _submit,
            isLoading: _isLoading,
            icon: _isLogin ? Icons.login : Icons.person_add,
          ),
        ],
      ),
    ),
  );

  Widget _buildSocialButtons() => AppTheme.buildFormCard(
    title: 'Or continue with',
    child: Row(
      children: [
        Expanded(child: _buildSocialButton('Google', Icons.g_mobiledata)),
        const SizedBox(width: 16),
        Expanded(child: _buildSocialButton('Facebook', Icons.facebook)),
      ],
    ),
  );

  Widget _buildSocialButton(String provider, IconData icon) => 
      AppWidgets.secondaryButton(
        text: provider,
        icon: icon,
        onPressed: () => _socialLogin(provider),
      );

  Widget _buildModeToggle() => TextButton(
    onPressed: () {
      if (_isLogin) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SignupWithOtpScreen()),
        );
      } else {
        setState(() {
          _isLogin = true;
          _clearForm();
        });
      }
    },
    child: RichText(
      text: TextSpan(
        style: const TextStyle(color: AppTheme.textSecondary),
        children: [
          TextSpan(text: _isLogin ? 'Don\'t have an account? ' : 'Already have an account? '),
          TextSpan(
            text: _isLogin ? 'Sign Up' : 'Sign In',
            style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    ),
  );

  void _clearForm() {
    _usernameController.clear();
    _emailController.clear();
    _passwordController.clear();
  }
  
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      bool success;
      
      if (_isLogin) {
        success = await authProvider.login(_usernameController.text, _passwordController.text);
      } else {
        success = await authProvider.signup(
          _usernameController.text, 
          _emailController.text, 
          _passwordController.text
        );
      }
      
      if (success) {
        showSuccess(_isLogin ? 'Login successful!' : 'Account created successfully!');
        navigateToHome();
      } else {
        showError(authProvider.errorMessage ?? (_isLogin ? 'Login failed' : 'Signup failed'));
      }
    } catch (e) {
      showError('An error occurred: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _socialLogin(String provider) async {
    setState(() => _isLoading = true);
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    try {
      print('Starting $provider login process...');
      
      if (provider == 'Google') {
        print('Checking Google Sign-In initialization...');
        if (!SocialLoginUtils.isInitialized) {
          print('Re-initializing SocialLoginUtils...');
          await SocialLoginUtils.initialize();
          await Future.delayed(const Duration(milliseconds: 1000)); 
        }
        
        if (SocialLoginUtils.googleSignInInstance == null) {
          throw Exception('Google Sign-In is not available. Please check your configuration.');
        }
        print('Google Sign-In instance is available, proceeding...');
      }
      
      bool success;
      if (provider == 'Google') {
        success = await authProvider.googleLoginApp();
      } else {
        success = await authProvider.facebookLogin();
      }
      
      if (success) {
        print('$provider login successful, navigating to home...');
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      } else {
        final errorMessage = authProvider.errorMessage ?? '$provider authentication failed';
        print('$provider login failed: $errorMessage');
        showError(errorMessage);
      }
    } catch (e) {
      print('$provider login exception: $e');
      showError('$provider authentication error: $e');
    }
    
    setState(() => _isLoading = false);
  }
}
