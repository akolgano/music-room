// lib/screens/auth/auth_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/core.dart';
import '../../widgets/app_widgets.dart';
import '../base_screen.dart';
import 'signup_with_otp_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

// Facebook and Google login is MUST HAVE for project requirement.
class _AuthScreenState extends BaseScreen<AuthScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
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
    return Scaffold(backgroundColor: AppTheme.background, body: SafeArea(child: buildContent()));
  }

  Widget _buildHeader() => Card(
    color: AppTheme.surface,
    elevation: 4,
    margin: const EdgeInsets.all(16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.music_note,
                color: AppTheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                _isLogin ? 'Welcome Back' : 'Join Music Room',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.music_note,
                size: 40,
                color: AppTheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _isLogin ? 'Sign in to continue your musical journey' : 'Create an account to start sharing music',
            style: const TextStyle(color: Colors.white70, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );

  Widget _buildForm() => AppTheme.buildFormCard(
    title: _isLogin ? 'Sign In' : 'Create Account',
    child: Form(
      key: _formKey,
      child: Column(
        children: [
          AppWidgets.textField(
            context: context,
            controller: _usernameController, 
            labelText: 'Username', 
            prefixIcon: Icons.person, 
            validator: AppValidators.username
          ),
          if (!_isLogin) ...[
            const SizedBox(height: 16),
            AppWidgets.textField(
              context: context,
              controller: _emailController,
              labelText: 'Email',
              prefixIcon: Icons.email,
              validator: AppValidators.email,
            ),
          ],
          const SizedBox(height: 16),
          AppWidgets.textField(
            context: context,
            controller: _passwordController,
            labelText: 'Password',
            prefixIcon: Icons.lock,
            obscureText: true,
            validator: AppValidators.password,
          ),
          if (_isLogin) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _forgotPassword,
                child: const Text(
                  'Forgot Password?',
                  style: TextStyle(
                    color: AppTheme.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          Consumer<AuthProvider>(
            builder: (context, authProvider, _) => AppWidgets.primaryButton(
              context: context,
              text: _isLogin ? 'Sign In' : 'Sign Up',
              onPressed: authProvider.isLoading ? null : _submit,
              isLoading: authProvider.isLoading,
              icon: _isLogin ? Icons.login : Icons.person_add,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildSocialButtons() => AppTheme.buildFormCard(
    title: 'Or continue with',
    child: Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        return Column(
          children: [
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: authProvider.isLoading ? null : () => _socialLogin('Google'),
                  icon: authProvider.isLoading 
                    ? const SizedBox(
                        width: 16, 
                        height: 16, 
                        child: CircularProgressIndicator(
                          strokeWidth: 2, 
                          color: Colors.red,
                        ),
                      )
                    : const Icon(Icons.g_mobiledata, color: Colors.red, size: 20),
                  label: Text(
                    authProvider.isLoading ? 'Signing in...' : 'Continue with Google',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    overflow: TextOverflow.visible,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.surface,
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 2,
                  ),
                ),
              ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: authProvider.isLoading ? null : () => _socialLogin('Facebook'),
                icon: authProvider.isLoading 
                  ? const SizedBox(
                      width: 16, 
                      height: 16, 
                      child: CircularProgressIndicator(
                        strokeWidth: 2, 
                        color: Colors.blue,
                      ),
                    )
                  : const Icon(Icons.facebook, color: Colors.blue, size: 20),
                label: Text(
                  authProvider.isLoading ? 'Signing in...' : 'Continue with Facebook',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  overflow: TextOverflow.visible,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.surface,
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.blue),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 2,
                ),
              ),
            ),
          ],
        );
      },
    ),
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
          TextSpan(text: _isLogin ? 'Sign Up' : 'Sign In',
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
    await runAsyncAction(
      () async {
        final authProvider = getProvider<AuthProvider>();
        bool success = await authProvider.login(_usernameController.text, _passwordController.text);
        if (success) {
          navigateToHome();
        }
        else {
          throw Exception(authProvider.errorMessage ?? 'Login failed');
        }
      },
      successMessage: 'Login successful!',
      errorMessage: 'Authentication failed',
    );
  }

  Future<void> _socialLogin(String provider) async {
    await runAsyncAction(
      () async {
        final authProvider = getProvider<AuthProvider>();
        bool success;
        if (provider == 'Google') {
          success = await authProvider.googleLogin();
        }
        else {
          success = await authProvider.facebookLogin();
        }
        if (success) {
          Navigator.pushReplacementNamed(context, AppRoutes.home);
        } else {
          throw Exception(authProvider.errorMessage ?? '$provider authentication failed');
        }
      },
      errorMessage: '$provider authentication failed',
    );
  }

  void _forgotPassword() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _ForgotPasswordDialog();
      },
    );
  }

}

class _ForgotPasswordDialog extends StatefulWidget {
  @override
  _ForgotPasswordDialogState createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<_ForgotPasswordDialog> {
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.surface,
      title: const Text(
        'Reset Password',
        style: TextStyle(color: Colors.white),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Enter your email address and we\'ll send you instructions to reset your password.',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          AppWidgets.textField(
            context: context,
            controller: _emailController,
            labelText: 'Email',
            prefixIcon: Icons.email,
            validator: AppValidators.email,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: () {
            if (_emailController.text.isNotEmpty) {
              final email = _emailController.text;
              Navigator.pop(context);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Password reset instructions sent to $email'),
                    backgroundColor: AppTheme.primary,
                  ),
                );
              }
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please enter your email address'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.black,
          ),
          child: const Text('Send Reset Link'),
        ),
      ],
    );
  }
}