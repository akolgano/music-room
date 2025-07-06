// lib/screens/profile/social_network_link_screen.dart
import 'package:flutter/material.dart';
import '../../providers/profile_provider.dart';
import '../../core/core.dart';
import '../../widgets/app_widgets.dart';
import '../base_screen.dart';

class SocialNetworkLinkScreen extends StatefulWidget {
  const SocialNetworkLinkScreen({Key? key}) : super(key: key);
  
  @override
  State<SocialNetworkLinkScreen> createState() => _SocialNetworkLinkScreenState();
}

class _SocialNetworkLinkScreenState extends BaseScreen<SocialNetworkLinkScreen> {
  @override
  String get screenTitle => 'Link Social Account';
  
  @override
  bool get showMiniPlayer => false;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await SocialLoginUtils.initialize();
    });
  }
  
  @override
  Widget buildContent() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 450),
          child: AppTheme.buildFormCard(
            title: 'Link Social Account',
            titleIcon: Icons.link,
            child: buildConsumerContent<ProfileProvider>(
              builder: (context, profileProvider) {
                return Column(
                  children: [
                    if (profileProvider.socialType != null) ...[
                      AppWidgets.infoBanner(
                        title: 'Connected',
                        message: 'Your account is linked to ${profileProvider.socialType!}',
                        icon: Icons.check_circle,
                        color: Colors.green,
                      ),
                      const SizedBox(height: 16),
                    ] else ...[
                      AppWidgets.infoBanner(
                        title: 'Link Social Account',
                        message: 'Connect your social media account for easier sign-in',
                        icon: Icons.info,
                      ),
                      const SizedBox(height: 16),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: SocialLoginButton(
                            provider: 'Google',
                            onPressed: profileProvider.socialType == null 
                                ? () => _linkWithProvider('Google', profileProvider)
                                : null,
                            isLoading: profileProvider.isLoading,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: SocialLoginButton(
                            provider: 'Facebook',
                            onPressed: profileProvider.socialType == null
                                ? () => _linkWithProvider('Facebook', profileProvider)
                                : null,
                            isLoading: profileProvider.isLoading,
                          ),
                        ),
                      ],
                    ),
                    if (profileProvider.hasError) ...[
                      const SizedBox(height: 16),
                      AppWidgets.errorBanner(
                        message: profileProvider.errorMessage ?? 'An error occurred',
                        onDismiss: () => profileProvider.clearMessages(),
                      ),
                    ],
                    if (profileProvider.hasSuccess) ...[
                      const SizedBox(height: 16),
                      AppWidgets.infoBanner(
                        title: 'Success',
                        message: profileProvider.successMessage ?? 'Account linked successfully',
                        icon: Icons.check_circle,
                        color: Colors.green,
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: navigateBack,
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Go Back'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
  
  Future<void> _linkWithProvider(String provider, ProfileProvider profileProvider) async {
    await runAsyncAction(
      () async {
        if (provider == 'Facebook') {
          await profileProvider.facebookLink(auth.token);
        } else if (provider == 'Google') {
          await profileProvider.googleLinkApp(auth.token);
        }
        
        await profileProvider.loadProfile(auth.token);
      },
      successMessage: '$provider account linked successfully!',
      errorMessage: 'Failed to link $provider account',
    );
  }
}
