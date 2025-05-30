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

class _AuthScreenState extends State<AuthScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  bool _isPasswordVisible = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimensions.paddingLarge),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    _buildWelcomeHeader(),
                    const SizedBox(height: 40),
                    _buildForm(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    return Column(
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 800),
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primary,
                      AppTheme.primary.withOpacity(0.7),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.music_note,
                  size: AppDimensions.iconXXXLarge,
                  color: Colors.black,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: AppDimensions.paddingLarge),
        
        Text(
          AppStrings.appName,
          style: TextStyle(
            fontSize: AppDimensions.textHeading,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Your Music, Your Way',
          style: TextStyle(
            fontSize: AppDimensions.textLarge,
            color: AppTheme.onSurfaceVariant,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 16),
        
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Icon(
                _isLogin ? Icons.waving_hand : Icons.celebration,
                color: AppTheme.primary,
                size: 24,
              ),
              const SizedBox(height: 8),
              Text(
                _isLogin 
                    ? 'Welcome back! Sign in to access your music library, playlists, and connect with friends.'
                    : 'Join Music Room today! Create playlists, discover new music, and share with friends.',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Card(
          color: AppTheme.surface,
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingLarge),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _isLogin ? Icons.login : Icons.person_add,
                        color: AppTheme.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isLogin ? 'Sign In to Your Account' : 'Create New Account',
                        style: TextStyle(
                          fontSize: AppDimensions.textTitle,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isLogin 
                        ? 'Enter your credentials to access your music'
                        : 'Fill in your details to get started',
                    style: const TextStyle(
                      color: AppTheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.paddingLarge),
                  
                  if (authProvider.hasError) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.error_outline, color: Colors.red, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Something went wrong',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            authProvider.errorMessage ?? AppStrings.somethingWentWrong,
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: AppDimensions.textMedium,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Please check your information and try again.',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDimensions.paddingMedium),
                  ],
                  
                  _buildFormField(
                    controller: _usernameController,
                    label: 'Username',
                    hint: 'Enter your username',
                    icon: Icons.person_outline,
                    validator: (v) => _validateRequired(v, 'username'),
                    description: _isLogin 
                        ? 'The username you used when signing up'
                        : 'Choose a unique username (letters, numbers, and underscores only)',
                  ),
                  const SizedBox(height: AppDimensions.paddingMedium),
                  
                  if (!_isLogin) ...[
                    _buildFormField(
                      controller: _emailController,
                      label: 'Email Address',
                      hint: 'Enter your email address',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: _validateEmail,
                      description: 'We\'ll use this to send you important updates about your account',
                    ),
                    const SizedBox(height: AppDimensions.paddingMedium),
                  ],
                  
                  _buildPasswordField(),
                  const SizedBox(height: AppDimensions.paddingLarge),
                  
                  authProvider.isLoading
                      ? _buildLoadingButton()
                      : _buildSubmitButton(),
                  const SizedBox(height: AppDimensions.paddingMedium),
                  
                  _buildSwitchModeSection(authProvider),
                  
                  if (!_isLogin) ...[
                    const SizedBox(height: AppDimensions.paddingMedium),
                    _buildSignupBenefits(),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? description,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        if (description != null) ...[
          Text(
            description,
            style: const TextStyle(
              color: AppTheme.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
        ],
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AppTheme.onSurfaceVariant),
            filled: true,
            fillColor: AppTheme.surfaceVariant,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.primary),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Password',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _isLogin 
              ? 'Enter your account password'
              : 'Create a strong password (at least 8 characters)',
          style: const TextStyle(
            color: AppTheme.onSurfaceVariant,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _passwordController,
          obscureText: !_isPasswordVisible,
          validator: _validatePassword,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: _isLogin ? 'Enter your password' : 'Create a secure password',
            prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.onSurfaceVariant),
            suffixIcon: IconButton(
              icon: Icon(
                _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                color: AppTheme.onSurfaceVariant,
              ),
              onPressed: () {
                setState(() {
                  _isPasswordVisible = !_isPasswordVisible;
                });
              },
              tooltip: _isPasswordVisible ? 'Hide password' : 'Show password',
            ),
            filled: true,
            fillColor: AppTheme.surfaceVariant,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.primary),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingButton() {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.7),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              color: Colors.black,
              strokeWidth: 2,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _isLogin ? 'Signing you in...' : 'Creating your account...',
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _submit,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.black,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        elevation: 3,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(_isLogin ? Icons.login : Icons.person_add, size: 20),
          const SizedBox(width: 8),
          Text(
            _isLogin ? 'Sign In to Music Room' : 'Create My Account',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchModeSection(AuthProvider authProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            _isLogin ? 'New to Music Room?' : 'Already have an account?',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              setState(() => _isLogin = !_isLogin);
              authProvider.clearError();
            },
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_isLogin ? Icons.person_add : Icons.login, size: 16),
                const SizedBox(width: 4),
                Text(
                  _isLogin ? 'Create a New Account' : 'Sign In Instead',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignupBenefits() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.star, color: AppTheme.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'What you get with Music Room:',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...[
            'Create unlimited custom playlists',
            'Discover and share music with friends',
            'Access millions of songs through Deezer',
            'Collaborate on playlists in real-time',
            'Vote on tracks for group listening sessions',
          ].map((benefit) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: AppTheme.primary, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    benefit,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  String? _validateRequired(String? value, String fieldName) {
    if (value?.isEmpty ?? true) {
      return 'Please enter your $fieldName';
    }
    if (fieldName == 'username' && value!.length < 3) {
      return 'Username must be at least 3 characters long';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value?.isEmpty ?? true) return 'Please enter your email address';
    if (!RegExp(AppConstants.emailRegexPattern).hasMatch(value!)) {
      return 'Please enter a valid email address (e.g., name@example.com)';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value?.isEmpty ?? true) return 'Please enter a password';
    if (value!.length < AppConstants.minPasswordLength) {
      return 'Password must be at least ${AppConstants.minPasswordLength} characters long';
    }
    if (_isLogin) return null;
    
    if (!value.contains(RegExp(r'[A-Za-z]'))) {
      return 'Password must contain at least one letter';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
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
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Text(_isLogin ? 'Welcome back to Music Room!' : 'Welcome to Music Room!'),
            ],
          ),
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
    _animationController.dispose();
    super.dispose();
  }
}
