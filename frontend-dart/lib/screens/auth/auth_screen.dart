// lib/screens/auth/auth_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/consolidated_core.dart';
import '../../widgets/unified_components.dart';
import '../../providers/auth_provider.dart';
import './forgot_password_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override  
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with AsyncOperationStateMixin<AuthScreen>, TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();
  
  bool _isLogin = true;
  bool _isPasswordVisible = false;
  bool _socialLoginLoading = false;

  bool _isOtp = false;
  String? _username;
  String? _email;
  String? _password;

  bool _isLoading = false;
  
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(duration: AppDurations.longDelay, vsync: this);
    _fadeAnimation = AppAnimations.fadeIn.animate(_fadeController);
    _fadeController.forward();
    
    SocialLoginUtils.initialize();
    
    SocialLoginUtils.setupGoogleWebCallback((account) {
      _handleGoogleWebLogin(account);
    });
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
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 32),
                      if (hasError) 
                        UnifiedComponents.errorBanner(
                          message: errorMessage!,
                          onDismiss: clearMessages,
                        ),
                      _buildFormCard(),
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
    );
  }

  Widget _buildHeader() {
    return UnifiedComponents.headerCard(
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

  Widget _buildFormCard() {
    return UnifiedComponents.formCard(
      title: _isLogin ? 'Sign In' : 'Create Account',
      titleIcon: _isLogin ? Icons.login : Icons.person_add,
      child: Column(
        children: [

          if(!_isOtp) ... [
          UnifiedComponents.textField(
            controller: _usernameController,
            labelText: AppStrings.username,
            prefixIcon: Icons.person,
            validator: ValidationUtils.username,
          ),
          const SizedBox(height: 16),
          ],

          if (!_isLogin && !_isOtp) ...[
            UnifiedComponents.textField(
              controller: _emailController,
              labelText: AppStrings.email,
              prefixIcon: Icons.email,
              validator: ValidationUtils.email,
            ),
          const SizedBox(height: 16),
          ],

          if(!_isOtp) ...[
          UnifiedComponents.textField(
            controller: _passwordController,
            labelText: AppStrings.password,
            prefixIcon: Icons.lock,
            obscureText: !_isPasswordVisible,
            validator: (value) => ValidationUtils.password(value),
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
          ],
          
          if (_isOtp) ...[
            UnifiedComponents.textField(
              controller: _otpController,
              labelText: 'One Time Passcode',
              prefixIcon: Icons.email,
              validator: (value) => ValidationUtils.otp(value),
            ),
            const SizedBox(height: 24),
          ],

          UnifiedComponents.primaryButton(
            text: _isLogin ? AppStrings.signIn : AppStrings.signUp,
            onPressed: _submit,
            icon: _isLogin ? Icons.login : Icons.person_add,
            isLoading: _isLoading,
          ),
          const SizedBox(height: 16),
          const Divider(color: AppTheme.surfaceVariant),
          TextButton(
            onPressed: _toggleMode,
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
    return UnifiedComponents.standardCard(
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
              Expanded(
                child: SocialLoginUtils.renderGoogleWebButton().runtimeType == SizedBox 
                  ? SocialLoginButton(
                      provider: 'Google',
                      onPressed: () => _loginWithSocial('Google'),
                      isLoading: _socialLoginLoading,
                    )
                  : SocialLoginUtils.renderGoogleWebButton(),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SocialLoginButton(
                  provider: 'Facebook',
                  onPressed: () => _loginWithSocial('Facebook'),
                  isLoading: _socialLoginLoading,
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

  void _toggleMode() {
    setState(() {
      _isLogin = !_isLogin;
      _clearForm();
      _isOtp = false;
    });
  }

  void _clearForm() {
    _usernameController.clear();
    _emailController.clear();
    _passwordController.clear();
    _isPasswordVisible = false;
    _formKey.currentState?.reset();
    clearMessages();
    _otpController.clear();
    _username = null;
    _email = null;
    _password = null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState((){_isLoading = true;});
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    bool success = false;
    
    if (_isLogin) {
      success = await executeBool(
        operation: () => authProvider.login(
          _usernameController.text.trim(), 
          _passwordController.text
        ),
        successMessage: AppStrings.loginSuccessful,
        errorMessage: 'Login failed. Please check your credentials.',
      );
    } else if (!_isOtp){

          _username = _usernameController.text.trim();
          _email = _emailController.text.trim();
          _password = _passwordController.text;
          bool isSentOtp = false;

          isSentOtp = await authProvider.signupEmailOtp(_email);
          if (isSentOtp) {
            setState((){_isOtp = true;});
            AppUtils.showSnackBar(context, "Please check your email for OTP verifictaion");
          }
          else {
            showError('Signup send OTP failed. Please try again.');
          }
          setState((){_isLoading = false;});
          return;
      }
      else if (_isOtp) {
        success = await authProvider.signup(
          _username!, 
          _email!,
          _password!,
          _otpController.text
        );
      }
      /*else {
      success = await executeBool(
        operation: () => authProvider.signup(
          _usernameController.text.trim(), 
          _emailController.text.trim(), 
          _passwordController.text,
        ),
        successMessage: AppStrings.accountCreated,
        errorMessage: 'Account creation failed. Please try again.',
      );
      }*/
    
    if (success) {
      showSuccess('$AppStrings.accountCreated');
    }
    else {
      if (authProvider.hasError){
        showError('${authProvider.errorMessage}');
      }
    }

    setState((){_isLoading = false;});

  }

  Future<void> _loginWithSocial(String provider) async {
    setState(() => _socialLoginLoading = true);
    
    try {
      SocialLoginResult result;
      
      if (provider == 'Facebook') {
        result = await SocialLoginUtils.loginWithFacebook();
      } else if (provider == 'Google') {
        result = await SocialLoginUtils.loginWithGoogle();
      } else {
        result = SocialLoginResult.error('Unknown provider');
      }
      
      if (result.success && result.token != null) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        bool success = false;
        
        if (provider == 'Facebook') {
          success = await authProvider.facebookLogin();
        } else if (provider == 'Google') {
          success = await authProvider.googleLoginApp();
        }
        
        if (success) {
          showSuccess(AppStrings.loginSuccessful);
        } else {
          showError('Social login failed. Please try again.');
        }
      } else {
        showError(result.error ?? 'Social login failed');
      }
    } catch (e) {
      showError('Social login error: $e');
    } finally {
      setState(() => _socialLoginLoading = false);
    }
  }

  Future<void> _handleGoogleWebLogin(account) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.googleLoginWeb(account);
    
    if (success) {
      showSuccess(AppStrings.loginSuccessful);
    } else {
      showError('Google login failed');
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
