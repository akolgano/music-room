// lib/screens/profile/components/music_preference_tab_view.dart
import 'package:flutter/material.dart';
import '../../../core/app_core.dart';
import '../../../providers/profile_provider.dart';
import '../../../providers/auth_provider.dart';
import 'package:provider/provider.dart';
import '../../../widgets/common_widgets.dart';


class MusicPreferenceTabView extends StatefulWidget {
  const MusicPreferenceTabView({Key? key}) : super(key: key);

  @override
  State<MusicPreferenceTabView> createState() => _MusicPreferenceTabViewState();
}

class _MusicPreferenceTabViewState extends State<MusicPreferenceTabView> {
  final _formKey = GlobalKey<FormState>();

  bool _prefsValidationError = false;
  
  final List<String> _prefs = [
    'Classical',
    'Jazz',
    'Pop',
    'Rock',
    'Rap',
    'R&B',
    'Techno',
  ];
  
  final Map<String, bool> _selectedPrefs = {};

  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profileProvider = Provider.of<ProfileProvider>(context, listen: false);

      setState(() {
        for (var pref in _prefs) {
          _selectedPrefs[pref] = profileProvider.musicPreferences?.contains(pref) ?? false;
        }
      });
      
    });
  }

  Future<void> _submit() async {
    try{

      setState((){
          _prefsValidationError = false;
      });

      if (!_formKey.currentState!.validate()) return;
      
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final profileProvider = Provider.of<ProfileProvider>(context, listen: false);

      if (authProvider.token == null) return;

      List<String> selected = [];
      for (var key in _selectedPrefs.keys) {
        if (_selectedPrefs[key] == true) {
          selected.add(key);
        }
      }

      if (selected.isEmpty){
        setState((){
          _prefsValidationError = true;
        });
        return;
      }

      bool success = false;
      success = await profileProvider.updateMusicPreferences(authProvider.token, selected);

      if (success) {
        await profileProvider.loadProfile(authProvider.token);
        CommonWidgets.showSnackBar(context, 'Update successful', backgroundColor: Colors.green);
      }

    } catch (e) {
        CommonWidgets.showSnackBar(context, 'Exception: $e', backgroundColor: Colors.red);
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
                      'Music Preferences',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),

                    if (_prefsValidationError) ...[
                        Padding(
                          padding: EdgeInsets.only(left: 16.0),
                          child: Text(
                            'Please select at least one music preference.',
                            style: TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ),
                    ],
                    
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _prefs.map((pref) {
                        return CheckboxListTile(
                          title: Text(pref),
                          value: _selectedPrefs[pref] ?? false,
                          onChanged: (bool? value) {
                            setState(() {
                              _selectedPrefs[pref] = value ?? false;
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

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
