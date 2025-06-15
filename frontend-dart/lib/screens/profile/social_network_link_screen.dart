// lib/screens/profile/social_network_link_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../core/consolidated_core.dart';
import '../../widgets/unified_components.dart';

class SocialNetworkLinkScreen extends StatefulWidget {
  const SocialNetworkLinkScreen({Key? key}) : super(key: key);

  @override 
  State<SocialNetworkLinkScreen> createState() => _SocialNetworkLinkScreenState();
}

class _SocialNetworkLinkScreenState extends State<SocialNetworkLinkScreen> with AsyncOperationStateMixin<SocialNetworkLinkScreen> {

  @override                                                                 
  void initState() {     
    super.initState();
    SocialLoginUtils.initialize();
    SocialLoginUtils.setupGoogleWebCallback(_handleGoogleWebLink);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        title: const Text('Link Social Network'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: UnifiedComponents.formCard(
              title: 'Link with Social Network',
              child: Consumer<ProfileProvider>(
                builder: (context, profileProvider, child) {
                  return Column(
                    children: [
                      if (hasError)
                        UnifiedComponents.errorBanner(
                          message: errorMessage!,
                          onDismiss: clearMessages,
                        ),

                      if (hasSuccess)
                        UnifiedComponents.successBanner(message: successMessage!),

                      if (profileProvider.socialType != null) ...[
                        UnifiedComponents.infoBanner(
                          title: 'Connected',
                          message: 'Your account is linked to ${profileProvider.socialType!}',
                          icon: Icons.check_circle,
                          color: Colors.green,
                        ),
                        const SizedBox(height: 16),
                      ],

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: SocialLoginUtils.renderGoogleWebButton().runtimeType == SizedBox 
                              ? SocialLoginButton(
                                  provider: 'Google',
                                  onPressed: () => _linkWithSocial('Google'),
                                  isLoading: isLoading,
                                )
                              : SocialLoginUtils.renderGoogleWebButton(),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: SocialLoginButton(
                              provider: 'Facebook',
                              onPressed: () => _linkWithSocial('Facebook'),
                              isLoading: isLoading,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 24),

                      if (isLoading)
                        const CircularProgressIndicator(color: AppTheme.primary),

                      const SizedBox(height: 24),
                      
                      TextButton(
                        onPressed: _goBack,
                        style: TextButton.styleFrom(foregroundColor: Colors.white),
                        child: const Text('Go Back'),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
    
  Future<void> _linkWithSocial(String provider) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    
    if (authProvider.token == null) {
      setError('Not authenticated');
      return;
    }

    try {
      SocialLoginResult result;
      
      if (provider == 'Facebook') {
        result = await SocialLoginUtils.loginWithFacebook();
      } else if (provider == 'Google') {
        result = await SocialLoginUtils.loginWithGoogle();
      } else {
        setError('Unknown social provider');
        return;
      }

      if (!result.success || result.token == null) {
        setError(result.error ?? 'Social login failed');
        return;
      }

      await executeBool(
        operation: () async {
          if (provider == 'Facebook') {
            await profileProvider.facebookLink(authProvider.token);
          } else if (provider == 'Google') {
            await profileProvider.googleLinkApp(authProvider.token);
          }
        },
        successMessage: '$provider account linked successfully!',
        errorMessage: 'Failed to link $provider account',
        onSuccess: () async {
          await profileProvider.loadProfile(authProvider.token);
        },
      );
    } catch (e) {
      setError('Error linking $provider account: $e');
    }
  }

  Future<void> _handleGoogleWebLink(account) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    
    if (authProvider.token == null) return;

    await executeBool(
      operation: () => profileProvider.googleLinkWeb(authProvider.token, account),
      successMessage: 'Google account linked successfully!',
      errorMessage: 'Failed to link Google account',
      onSuccess: () async {
        await profileProvider.loadProfile(authProvider.token);
      },
    );
  }

  Future<void> _goBack() async {
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    await profileProvider.loadProfile(authProvider.token);
    Navigator.pop(context);
  }
}
