// lib/screens/auth/auth_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/consolidated_core.dart';
import '../../core/form_helpers.dart';
import '../../widgets/app_widgets.dart';
import 'signup_with_otp_screen.dart';

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
  bool _isLoading = false;
  late AnimationController _rotationController;

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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Center(
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
        ),
      ),
    );
  }

  Widget _buildHeader() => AppTheme.buildFormCard(
    title: _isLogin ? 'Welcome Back' : 'Join Music Room',
    titleIcon: Icons.music_note,
    child: Column(
      children: [
        AnimatedBuilder(
          animation: _rotationController,
          child: const Icon(Icons.music_note, size: 40, color: AppTheme.primary),
          builder: (context, child) => Transform.rotate(
            angle: _rotationController.value * 2 * 3.14159, 
            child: child
          ),
        ),
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
          FormHelpers.buildTextFormField(
            controller: _usernameController,
            labelText: 'Username',
            prefixIcon: Icons.person,
            validator: AppValidators.username,
          ),
          if (!_isLogin) ...[
            const SizedBox(height: 16),
            FormHelpers.buildTextFormField(
              controller: _emailController,
              labelText: 'Email',
              prefixIcon: Icons.email,
              validator: AppValidators.email,
            ),
          ],
          const SizedBox(height: 16),
          FormHelpers.buildTextFormField(
            controller: _passwordController,
            labelText: 'Password',
            prefixIcon: Icons.lock,
            obscureText: true,
            validator: AppValidators.password,
          ),
          const SizedBox(height: 24),
          FormHelpers.buildPrimaryButton(
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
      FormHelpers.buildSecondaryButton(
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
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    try {
      bool success;
      if (_isLogin) {
        success = await authProvider.login(_usernameController.text.trim(), _passwordController.text);
      } else {
        success = await authProvider.signup(
          _usernameController.text.trim(), 
          _emailController.text.trim(), 
          _passwordController.text
        );
      }
      
      if (success) {
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      } else {
        final errorMessage = authProvider.errorMessage ?? 'Authentication failed';
        _showError(errorMessage);
      }
    } catch (e) {
      _showError('An unexpected error occurred: $e');
    }
    
    setState(() => _isLoading = false);
  }

  Future<void> _socialLogin(String provider) async {
    setState(() => _isLoading = true);
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    try {
      bool success;
      if (provider == 'Google') {
        success = await authProvider.googleLoginApp();
      } else {
        success = await authProvider.facebookLogin();
      }
      
      if (success) {
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      } else {
        final errorMessage = authProvider.errorMessage ?? '$provider authentication failed';
        _showError(errorMessage);
      }
    } catch (e) {
      _showError('$provider authentication error: $e');
    }
    
    setState(() => _isLoading = false);
  }

  void _showError(String message) {
    AppWidgets.showSnackBar(context, message, backgroundColor: AppTheme.error);
  }
}
