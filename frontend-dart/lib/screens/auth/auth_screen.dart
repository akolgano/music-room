import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme_utils.dart';
import '../../core/validators.dart';
import '../../core/constants.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/custom_scrollbar.dart';
import '../base_screen.dart';
import 'signup_with_otp_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

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
      child: CustomSingleChildScrollView(
        padding: EdgeInsets.all(ThemeUtils.isSmallMobile(context) ? 8 : ThemeUtils.getResponsivePadding(context)),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: ThemeUtils.isSmallMobile(context) ? double.infinity : 400),
          child: Column(
            children: [
              _buildHeader(), 
              SizedBox(height: ThemeUtils.isSmallMobile(context) ? 16 : 32),
              _buildForm(), 
              SizedBox(height: ThemeUtils.isSmallMobile(context) ? 12 : 24),
              _buildSocialButtons(), 
              SizedBox(height: ThemeUtils.isSmallMobile(context) ? 8 : 16), 
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
    elevation: ThemeUtils.isSmallMobile(context) ? 2 : 4,
    margin: ThemeUtils.isSmallMobile(context) ? EdgeInsets.zero : ThemeUtils.getResponsiveCardMargin(context),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ThemeUtils.getResponsiveBorderRadius(context))),
    child: Padding(
      padding: ThemeUtils.isSmallMobile(context) ? const EdgeInsets.all(12) : ThemeUtils.getResponsiveCardPadding(context),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            _isLogin ? 'Welcome Back' : 'Join Music Room',
            style: ThemeUtils.getSubheadingStyle(context).copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: ThemeUtils.isSmallMobile(context) ? 8 : 16),
          Center(
            child: Container(
              padding: EdgeInsets.all(ThemeUtils.isSmallMobile(context) ? 4 : 6),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(ThemeUtils.getResponsiveBorderRadius(context)),
              ),
              child: Image.asset(
                'assets/images/musicroom.png',
                width: ThemeUtils.isSmallMobile(context) ? 24 : 40,
                height: ThemeUtils.isSmallMobile(context) ? 24 : 40,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.music_note,
                    size: ThemeUtils.isSmallMobile(context) ? 24 : 40,
                    color: AppTheme.primary,
                  );
                },
              ),
            ),
          ),
          SizedBox(height: ThemeUtils.isSmallMobile(context) ? 8 : 16),
          Text(
            _isLogin ? 'Sign in to continue your musical journey' : 'Create an account to start sharing music',
            style: ThemeUtils.getCaptionStyle(context).copyWith(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );

  Widget _buildForm() => Card(
    color: AppTheme.surface,
    elevation: ThemeUtils.isSmallMobile(context) ? 2 : 4,
    margin: ThemeUtils.isSmallMobile(context) ? EdgeInsets.zero : const EdgeInsets.all(8),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ThemeUtils.getResponsiveBorderRadius(context))),
    child: Padding(
      padding: ThemeUtils.isSmallMobile(context) ? const EdgeInsets.all(12) : const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.login, color: AppTheme.primary, size: ThemeUtils.isSmallMobile(context) ? 18 : 20),
              SizedBox(width: ThemeUtils.isSmallMobile(context) ? 4 : 8),
              Flexible(
                child: Text(
                  _isLogin ? 'Sign In' : 'Create Account',
                  style: ThemeUtils.getSubheadingStyle(context).copyWith(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: ThemeUtils.isSmallMobile(context) ? 8 : 12),
          Form(
            key: _formKey,
            child: Column(
              children: [
                AppWidgets.textField(
                  context: context,
                  controller: _usernameController, 
                  labelText: 'Username', 
                  prefixIcon: Icons.person, 
                  validator: AppValidators.username,
                  onFieldSubmitted: kIsWeb ? (_) => _submit() : null,
                ),
                if (!_isLogin) ...[
                  SizedBox(height: ThemeUtils.isSmallMobile(context) ? 8 : 16),
                  AppWidgets.textField(
                    context: context,
                    controller: _emailController,
                    labelText: 'Email',
                    prefixIcon: Icons.email,
                    validator: AppValidators.email,
                    onFieldSubmitted: kIsWeb ? (_) => _submit() : null,
                  ),
                ],
                SizedBox(height: ThemeUtils.isSmallMobile(context) ? 8 : 16),
                AppWidgets.textField(
                  context: context,
                  controller: _passwordController,
                  labelText: 'Password',
                  prefixIcon: Icons.lock,
                  obscureText: true,
                  validator: AppValidators.password,
                  onFieldSubmitted: kIsWeb ? (_) => _submit() : null,
                ),
                if (_isLogin) ...[
                  SizedBox(height: ThemeUtils.isSmallMobile(context) ? 4 : 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _forgotPassword,
                      child: Text(
                        'Forgot Password?',
                        style: ThemeUtils.getCaptionStyle(context).copyWith(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
                SizedBox(height: ThemeUtils.isSmallMobile(context) ? 12 : 24),
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
        ],
      ),
    ),
  );

  Widget _buildSocialButtons() => Card(
    color: AppTheme.surface,
    elevation: ThemeUtils.isSmallMobile(context) ? 2 : 4,
    margin: ThemeUtils.isSmallMobile(context) ? EdgeInsets.zero : const EdgeInsets.all(8),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ThemeUtils.getResponsiveBorderRadius(context))),
    child: Padding(
      padding: ThemeUtils.isSmallMobile(context) ? const EdgeInsets.all(12) : const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.login, color: AppTheme.primary, size: ThemeUtils.isSmallMobile(context) ? 18 : 20),
              SizedBox(width: ThemeUtils.isSmallMobile(context) ? 4 : 8),
              Flexible(
                child: Text(
                  'Or continue with',
                  style: ThemeUtils.getSubheadingStyle(context).copyWith(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: ThemeUtils.isSmallMobile(context) ? 8 : 12),
          Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        return Column(
          children: [
              SizedBox(
                width: double.infinity,
                height: ThemeUtils.getResponsiveButtonHeight(context),
                child: ElevatedButton.icon(
                  onPressed: authProvider.isLoading ? null : () => _socialLogin('Google'),
                  icon: authProvider.isLoading 
                    ? SizedBox(
                        width: ThemeUtils.isSmallMobile(context) ? 12 : 16, 
                        height: ThemeUtils.isSmallMobile(context) ? 12 : 16, 
                        child: const CircularProgressIndicator(
                          strokeWidth: 2, 
                          color: Colors.red,
                        ),
                      )
                    : Icon(Icons.g_mobiledata, color: Colors.red, size: ThemeUtils.getResponsiveIconSize(context)),
                  label: Text(
                    authProvider.isLoading ? 'Signing in...' : 'Continue with Google',
                    style: ThemeUtils.getCaptionStyle(context).copyWith(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.surface,
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ThemeUtils.getResponsiveBorderRadius(context))),
                    elevation: ThemeUtils.isSmallMobile(context) ? 1 : 2,
                  ),
                ),
              ),
            SizedBox(height: ThemeUtils.isSmallMobile(context) ? 6 : 12),
            SizedBox(
              width: double.infinity,
              height: ThemeUtils.getResponsiveButtonHeight(context),
              child: ElevatedButton.icon(
                onPressed: authProvider.isLoading ? null : () => _socialLogin('Facebook'),
                icon: authProvider.isLoading 
                  ? SizedBox(
                      width: ThemeUtils.isSmallMobile(context) ? 12 : 16, 
                      height: ThemeUtils.isSmallMobile(context) ? 12 : 16, 
                      child: const CircularProgressIndicator(
                        strokeWidth: 2, 
                        color: Colors.blue,
                      ),
                    )
                  : Icon(Icons.facebook, color: Colors.blue, size: ThemeUtils.getResponsiveIconSize(context)),
                label: Text(
                  authProvider.isLoading ? 'Signing in...' : 'Continue with Facebook',
                  style: ThemeUtils.getCaptionStyle(context).copyWith(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.surface,
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.blue),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ThemeUtils.getResponsiveBorderRadius(context))),
                  elevation: ThemeUtils.isSmallMobile(context) ? 1 : 2,
                ),
              ),
            ),
          ],
        );
      },
    ),
        ],
      ),
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
          if (mounted) {
            Navigator.pushReplacementNamed(context, AppRoutes.home);
          }
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
            onFieldSubmitted: kIsWeb ? (_) {
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
              }
            } : null,
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