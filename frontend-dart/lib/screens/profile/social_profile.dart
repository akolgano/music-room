import 'package:flutter/material.dart';
import '../../providers/profile_providers.dart';
import '../../core/theme_core.dart';
import '../../core/social_core.dart';
import '../../widgets/app_widgets.dart';
import '../base_screens.dart';

class SocialNetworkLinkScreen extends StatefulWidget {
  const SocialNetworkLinkScreen({super.key});
  @override 
  State<SocialNetworkLinkScreen> createState() => _SocialNetworkLinkScreenState();
}

class _SocialNetworkLinkScreenState extends BaseScreen<SocialNetworkLinkScreen> {
  @override
  String get screenTitle => 'Link Social Network';
  @override
  bool get showMiniPlayer => false;
  @override                                                                 
  void initState() {     
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => SocialLoginUtils.initialize());
  }

  Future<void> _linkSocial(String provider, ProfileProvider profileProvider) async {
    if (auth.token == null) return showError('Not authenticated');
    try {
      final success = provider == 'Google' 
        ? await profileProvider.googleLink(auth.token)
        : await profileProvider.facebookLink(auth.token);
      if (success) {
        await profileProvider.loadProfile(auth.token);
        showSuccess('$provider account linked successfully!');
      }
    } catch (e) {
      showError('Failed to link $provider account');
    }
  }

  @override
  Widget buildContent() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(5),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 450),
          child: AppTheme.buildFormCard( 
            title: 'Link with Social Network',
            titleIcon: Icons.link,
            context: context,
            child: buildConsumerContent<ProfileProvider>(
              builder: (context, profileProvider) {
                return Column(
                  children: [
                    AppWidgets.infoBanner(
                      title: profileProvider.socialType != null ? 'Connected' : 'Link Social Account',
                      message: profileProvider.socialType != null 
                        ? 'Your account is linked to ${profileProvider.socialType!}'
                        : 'Connect your social media account for easier sign-in',
                      icon: profileProvider.socialType != null ? Icons.check_circle : Icons.info,
                      color: profileProvider.socialType != null ? Colors.green : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: ['Google', 'Facebook'].map((provider) => Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(left: provider == 'Facebook' ? 8 : 0, right: provider == 'Google' ? 8 : 0),
                          child: SocialLoginButton(
                            provider: provider,
                            onPressed: profileProvider.isLoading ? null : () => _linkSocial(provider, profileProvider),
                            isLoading: profileProvider.isLoading,
                          ),
                        ),
                      )).toList(),
                    ),
                    if (profileProvider.isLoading) ...[
                      const SizedBox(height: 24),
                      const CircularProgressIndicator(color: AppTheme.primary),
                    ],
                    const SizedBox(height: 24),
                    AppWidgets.secondaryButton(context: context, text: 'Go Back', onPressed: navigateBack, icon: Icons.arrow_back),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
