// screens/profile/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import './social_network_link_screen.dart';
import './user_password_change_screen.dart';


class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override State<ProfileScreen> createState() => _ProfileScreenState();
}


class _ProfileScreenState extends State<ProfileScreen> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
      profileProvider.loadProfile(authProvider.token);
    });
  }


  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final profileProvider = Provider.of<ProfileProvider>(context);

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Profile',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey[300],
                    child: const Icon(Icons.person, size: 50),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    authProvider.username ?? 'User',
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 20),
                  ListTile(
                    leading: const Icon(Icons.public),
                    title: const Text('Public Information'),
                    trailing: const Icon(Icons.edit),
                    onTap: () {
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.group),
                    title: const Text('Friends-Only Information'),
                    trailing: const Icon(Icons.edit),
                    onTap: () {
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.lock),
                    title: const Text('Private Information'),
                    trailing: const Icon(Icons.edit),
                    onTap: () {
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.music_note),
                    title: const Text('Music Preferences'),
                    trailing: const Icon(Icons.edit),
                    onTap: () {
                    },
                  ),
                  
                  if (profileProvider.isPasswordUsable) ...[
                    ListTile(
                      leading: const Icon(Icons.music_note),
                      title: const Text('Password Change'),
                      trailing: const Icon(Icons.edit),
                      onTap: () {
                        Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UserPasswordChangeScreen(),
                        ),
                      );
                      },
                    ),
                  ],

                  ListTile(
                    leading: const Icon(Icons.link),
                    title: const Text('Social Network Linked'),
                    subtitle: Column(
                      children: [

                        if (profileProvider.socialType == 'google') ...[
                          Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => {},
                                icon: const Icon(Icons.g_mobiledata),
                                label: const Text('Google'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  side: const BorderSide(color: Colors.white),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(32),
                                  ),
                                ),
                              ),
                            ),
                          ],
                          ),
                        ],

                      if (profileProvider.socialType == 'facebook') ...[
                        Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => {},
                              icon: const Icon(Icons.facebook),
                              label: const Text('Facebook'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                side: const BorderSide(color: Colors.white),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(32),
                                ),
                              ),
                            ),
                          ),
                        ],
                        ),
                      ],

                      ],
                    ),
                    trailing: profileProvider.socialType == null 
                              ? const Icon(Icons.edit)
                              : null,
                    onTap: () {
                      if (profileProvider.socialType == null) {
                          Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SocialNetworkLinkScreen(),
                          ),
                        );
                      }
                    },
                  ),

                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}