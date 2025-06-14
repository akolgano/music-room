// lib/screens/profile/components/public_bio_tab_view.dart
import 'package:flutter/material.dart';
import '../../../core/app_core.dart';
import '../../../providers/profile_provider.dart';
import '../../../providers/auth_provider.dart';
import 'package:provider/provider.dart';
import '../../../widgets/unified_components.dart';

class PublicBioTabView extends StatefulWidget {
  const PublicBioTabView({Key? key}) : super(key: key);

  @override
  State<PublicBioTabView> createState() => _PublicBioTabViewState();
}

class _PublicBioTabViewState extends State<PublicBioTabView> {
  final _formKey = GlobalKey<FormState>();
  final _bioController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
      if (profileProvider.bio != null) {
        _bioController.text = profileProvider.bio!;
      }
    });
  }

  Future<void> _submit() async {
    try{

      if (!_formKey.currentState!.validate()) return;
      
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final profileProvider = Provider.of<ProfileProvider>(context, listen: false);

      if (authProvider.token == null) return;

      bool success = false;
      success = await profileProvider.updatePublicBio(authProvider.token,_bioController.text);

      if (success) {
        await profileProvider.loadProfile(authProvider.token);
        UnifiedComponents.showSnackBar(context, 'Update successful', backgroundColor: Colors.green);
      }
    } catch (e) {
        UnifiedComponents.showSnackBar(context, 'Exception: $e', backgroundColor: Colors.red);
        return ;
      }  
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileProvider>(
      builder: (context, profileProvider, child) {

        return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: AppTheme.surface,
            child: Padding(
              padding: const EdgeInsets.all(24),
                child: Form(
                key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [

                    if (profileProvider.hasError) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                profileProvider.errorMessage ?? 'An error occurred',
                                style: const TextStyle(color: Colors.red, fontSize: 14),
                              ),
                            ),  
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],    

                    Text(
                      'Bio',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    UnifiedComponents.textField(
                      controller: _bioController,
                      labelText: 'Something about yourself',
                      minLines: 5,
                      maxLines: 10,
                      validator: (v) => v?.isEmpty ?? true ? 'Please enter a bio' : 
                                v!.length > 500 ? 'Bio maximum 500 characters' : null,
                    ),
                    const SizedBox(height: 24),

                    profileProvider.isLoading
                      ? const CircularProgressIndicator(color: AppTheme.primary)
                      : 
                        ElevatedButton(
                          onPressed: _submit,
                          child: Text('Save'),
                        ),
                    ],

                  ),
                ),
            ),
          ),
        ]
        );

      }
    );
  }
}
