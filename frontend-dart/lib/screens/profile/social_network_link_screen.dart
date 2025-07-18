import 'package:flutter/material.dart';
import '../../providers/profile_provider.dart';
import '../../core/core.dart';
import '../../widgets/app_widgets.dart';
import '../base_screen.dart';

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
            title: 'Link with Social Network',
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
                            onPressed: () => _linkWithSocial('Google'), 
                            isLoading: profileProvider.isLoading,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: SocialLoginButton(
                            provider: 'Facebook', onPressed: () => _linkWithSocial('Facebook'),
                            isLoading: profileProvider.isLoading,
                          ),
                        ),
                      ],
                    ),
                    if (profileProvider.isLoading) ...[const SizedBox(height: 24),
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

  Future<void> _linkWithSocial(String provider) async {
    if (auth.token == null) {
      showError('Not authenticated');
      return;
    }

    await runAsyncAction(
      () async {

        final profileProvider = getProvider<ProfileProvider>();
        if (provider == 'Facebook') {
          await profileProvider.facebookLink(auth.token);
        }
        else if (provider == 'Google') {
          await profileProvider.googleLink(auth.token);
        }
        await profileProvider.loadProfile(auth.token);

      },
      successMessage: '$provider account linked successfully!',
      errorMessage: 'Failed to link $provider account',
    );

  }
}
