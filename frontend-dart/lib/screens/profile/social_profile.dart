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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await SocialLoginUtils.initialize();
    });
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
                            onPressed: profileProvider.isLoading ? null : () async {
                              if (auth.token == null) {
                                showError('Not authenticated');
                                return;
                              }
                              try {
                                final success = await profileProvider.googleLink(auth.token);
                                if (success) {
                                  await profileProvider.loadProfile(auth.token);
                                  showSuccess('Google account linked successfully!');
                                }
                              } catch (e) {
                                showError('Failed to link Google account');
                              }
                            }, 
                            isLoading: profileProvider.isLoading,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: SocialLoginButton(
                            provider: 'Facebook', 
                            onPressed: profileProvider.isLoading ? null : () async {
                              if (auth.token == null) {
                                showError('Not authenticated');
                                return;
                              }
                              try {
                                final success = await profileProvider.facebookLink(auth.token);
                                if (success) {
                                  await profileProvider.loadProfile(auth.token);
                                  showSuccess('Facebook account linked successfully!');
                                }
                              } catch (e) {
                                showError('Failed to link Facebook account');
                              }
                            },
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
}
