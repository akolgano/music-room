import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import '../../providers/auth_providers.dart';
import '../../core/theme_core.dart';
import '../../core/responsive_core.dart';
import '../../core/constants_core.dart';
import '../../core/logging_core.dart';
import '../../widgets/app_widgets.dart';
import '../base_screens.dart';
import 'signup_auth.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends BaseScreen<AuthScreen> with TickerProviderStateMixin, UserActionLoggingMixin {
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
        padding: EdgeInsets.all(MusicAppResponsive.isSmallScreen(context) ? 8 : ThemeUtils.getResponsivePadding(context)),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: MusicAppResponsive.isSmallScreen(context) ? double.infinity : 400),
          child: Column(
            children: [
              _buildHeader(), 
              SizedBox(height: MusicAppResponsive.isSmallScreen(context) ? 16 : 32),
              _buildForm(), 
              SizedBox(height: MusicAppResponsive.isSmallScreen(context) ? 12 : 24),
              _buildSocialButtons(), 
              SizedBox(height: MusicAppResponsive.isSmallScreen(context) ? 8 : 16), 
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
    elevation: MusicAppResponsive.isSmallScreen(context) ? 2 : 4,
    margin: MusicAppResponsive.isSmallScreen(context) ? EdgeInsets.zero : EdgeInsets.all(ThemeUtils.getResponsiveMargin(context)),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ThemeUtils.getResponsiveBorderRadius(context))),
    child: Padding(
      padding: MusicAppResponsive.isSmallScreen(context) ? const EdgeInsets.all(12) : EdgeInsets.all(ThemeUtils.getResponsivePadding(context)),
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
          SizedBox(height: MusicAppResponsive.isSmallScreen(context) ? 8 : 16),
          Center(
            child: Container(
              padding: EdgeInsets.all(MusicAppResponsive.isSmallScreen(context) ? 4 : 6),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(ThemeUtils.getResponsiveBorderRadius(context)),
              ),
              child: Image.asset(
                'assets/images/musicroom.png',
                width: MusicAppResponsive.isSmallScreen(context) ? 24 : 40,
                height: MusicAppResponsive.isSmallScreen(context) ? 24 : 40,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.music_note,
                    size: MusicAppResponsive.isSmallScreen(context) ? 24 : 40,
                    color: AppTheme.primary,
                  );
                },
              ),
            ),
          ),
          SizedBox(height: MusicAppResponsive.isSmallScreen(context) ? 8 : 16),
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
    elevation: MusicAppResponsive.isSmallScreen(context) ? 2 : 4,
    margin: MusicAppResponsive.isSmallScreen(context) ? EdgeInsets.zero : const EdgeInsets.all(8),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ThemeUtils.getResponsiveBorderRadius(context))),
    child: Padding(
      padding: MusicAppResponsive.isSmallScreen(context) ? const EdgeInsets.all(12) : const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.login, color: AppTheme.primary, size: MusicAppResponsive.isSmallScreen(context) ? 18 : 20),
              SizedBox(width: MusicAppResponsive.isSmallScreen(context) ? 4 : 8),
              Flexible(
                child: Text(
                  _isLogin ? 'Sign In' : 'Create Account',
                  style: ThemeUtils.getSubheadingStyle(context).copyWith(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: MusicAppResponsive.isSmallScreen(context) ? 8 : 12),
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
                  SizedBox(height: MusicAppResponsive.isSmallScreen(context) ? 8 : 16),
                  AppWidgets.textField(
                    context: context,
                    controller: _emailController,
                    labelText: 'Email',
                    prefixIcon: Icons.email,
                    validator: AppValidators.email,
                    onFieldSubmitted: kIsWeb ? (_) => _submit() : null,
                  ),
                ],
                SizedBox(height: MusicAppResponsive.isSmallScreen(context) ? 8 : 16),
                AppWidgets.textField(
                  context: context,
                  controller: _passwordController,
                  labelText: 'Password',
                  prefixIcon: Icons.lock,
                  obscureText: true,
                  validator: (value) => AppValidators.password(value, 8),
                  onFieldSubmitted: kIsWeb ? (_) => _submit() : null,
                ),
                if (_isLogin) ...[
                  SizedBox(height: MusicAppResponsive.isSmallScreen(context) ? 4 : 8),
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
                SizedBox(height: MusicAppResponsive.isSmallScreen(context) ? 12 : 24),
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
    elevation: MusicAppResponsive.isSmallScreen(context) ? 2 : 4,
    margin: MusicAppResponsive.isSmallScreen(context) ? EdgeInsets.zero : const EdgeInsets.all(8),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ThemeUtils.getResponsiveBorderRadius(context))),
    child: Padding(
      padding: MusicAppResponsive.isSmallScreen(context) ? const EdgeInsets.all(12) : const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.login, color: AppTheme.primary, size: MusicAppResponsive.isSmallScreen(context) ? 18 : 20),
              SizedBox(width: MusicAppResponsive.isSmallScreen(context) ? 4 : 8),
              Flexible(
                child: Text(
                  'Or continue with',
                  style: ThemeUtils.getSubheadingStyle(context).copyWith(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: MusicAppResponsive.isSmallScreen(context) ? 8 : 12),
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
                        width: MusicAppResponsive.isSmallScreen(context) ? 12 : 16, 
                        height: MusicAppResponsive.isSmallScreen(context) ? 12 : 16, 
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
                    elevation: MusicAppResponsive.isSmallScreen(context) ? 1 : 2,
                  ),
                ),
              ),
            SizedBox(height: MusicAppResponsive.isSmallScreen(context) ? 6 : 12),
            SizedBox(
              width: double.infinity,
              height: ThemeUtils.getResponsiveButtonHeight(context),
              child: ElevatedButton.icon(
                onPressed: authProvider.isLoading ? null : () => _socialLogin('Facebook'),
                icon: authProvider.isLoading 
                  ? SizedBox(
                      width: MusicAppResponsive.isSmallScreen(context) ? 12 : 16, 
                      height: MusicAppResponsive.isSmallScreen(context) ? 12 : 16, 
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
                  elevation: MusicAppResponsive.isSmallScreen(context) ? 1 : 2,
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
        logButtonClick('switch_to_signup_button');
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SignupWithOtpScreen()),
        );
      } else {
        logButtonClick('switch_to_login_button');
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
    if (!_formKey.currentState!.validate()) {
      logFormSubmit(_isLogin ? 'login_form' : 'signup_form', success: false, metadata: {'reason': 'validation_failed'});
      return;
    }
    
    logFormSubmit(_isLogin ? 'login_form' : 'signup_form', metadata: {'username': _usernameController.text});
    
    await runAsyncAction(
      () async {
        final authProvider = getProvider<AuthProvider>();
        bool success = await authProvider.login(_usernameController.text, _passwordController.text);
        if (success) {
          logAuthAction(_isLogin ? 'login' : 'signup', success: true, metadata: {'username': _usernameController.text});
          navigateToHome();
        }
        else {
          logAuthAction(_isLogin ? 'login' : 'signup', success: false, metadata: {'username': _usernameController.text, 'error': authProvider.errorMessage});
          throw Exception(authProvider.errorMessage ?? 'Login failed');
        }
      },
      successMessage: 'Login successful!',
      errorMessage: 'Authentication failed',
    );
  }

  Future<void> _socialLogin(String provider) async {
    logButtonClick('${provider.toLowerCase()}_login_button', metadata: {'provider': provider});
    
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
          logAuthAction('social_login', success: true, metadata: {'provider': provider});
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/');
          }
        } else {
          logAuthAction('social_login', success: false, metadata: {'provider': provider, 'error': authProvider.errorMessage});
          throw Exception(authProvider.errorMessage ?? '$provider authentication failed');
        }
      },
    );
  }

  void _forgotPassword() {
    logButtonClick('forgot_password_button');
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
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _otpSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _sendResetLink() async {
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your email address'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final emailValidation = AppValidators.email(_emailController.text);
    if (emailValidation != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(emailValidation),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.sendPasswordResetEmail(_emailController.text);
      
      if (success && mounted) {
        setState(() {
          _otpSent = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('OTP sent to ${_emailController.text}. Please enter the code and your new password.'),
            backgroundColor: AppTheme.primary,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage ?? 'Failed to send reset email'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resetPassword() async {
    if (_otpController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the OTP code'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!RegExp(r'^\d{6}$').hasMatch(_otpController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OTP must be exactly 6 digits'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a new password'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_passwordController.text.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password must be at least 8 characters'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.resetPasswordWithOtp(
        _emailController.text,
        _otpController.text,
        _passwordController.text,
      );
      
      if (success && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage ?? 'Failed to reset password'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.surface,
      title: Text(
        _otpSent ? 'Reset Password' : 'Forgot Password',
        style: const TextStyle(color: Colors.white),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!_otpSent) ...[
            const Text(
              'Enter your email address and we\'ll send you an OTP to reset your password.',
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
          ] else ...[
            Text(
              'Enter the OTP sent to ${_emailController.text} and your new password.',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            AppWidgets.textField(
              context: context,
              controller: _otpController,
              labelText: 'OTP Code',
              prefixIcon: Icons.lock,
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Please enter OTP';
                if (!RegExp(r'^\d{6}$').hasMatch(value!)) return 'OTP must be 6 digits';
                return null;
              },
            ),
            const SizedBox(height: 16),
            AppWidgets.textField(
              context: context,
              controller: _passwordController,
              labelText: 'New Password',
              prefixIcon: Icons.lock,
              obscureText: true,
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Please enter password';
                if (value!.length < 8) return 'Password must be at least 8 characters';
                return null;
              },
            ),
            const SizedBox(height: 16),
            AppWidgets.textField(
              context: context,
              controller: _confirmPasswordController,
              labelText: 'Confirm Password',
              prefixIcon: Icons.lock,
              obscureText: true,
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Please confirm password';
                if (value != _passwordController.text) return 'Passwords do not match';
                return null;
              },
            ),
          ],
        ],
      ),
      actions: [
        if (_otpSent)
          TextButton(
            onPressed: () => setState(() {
              _otpSent = false;
              _otpController.clear();
              _passwordController.clear();
              _confirmPasswordController.clear();
            }),
            child: const Text('Back', style: TextStyle(color: Colors.grey)),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : (_otpSent ? _resetPassword : _sendResetLink),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.black,
          ),
          child: _isLoading 
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.black,
                ),
              )
            : Text(_otpSent ? 'Reset Password' : 'Send OTP'),
        ),
      ],
    );
  }
}
