// lib/screens/profile/components/public_basic_tab_view.darts
import 'package:flutter/material.dart';
import '../../../core/app_core.dart';
import '../../../providers/profile_provider.dart';
import '../../../providers/auth_provider.dart';
import 'package:provider/provider.dart';
import '../../../widgets/common_widgets.dart';


class PublicBasicTabView extends StatefulWidget {
  const PublicBasicTabView({Key? key}) : super(key: key);

  @override
  State<PublicBasicTabView> createState() => _PublicBasicTabViewState();
}

class _PublicBasicTabViewState extends State<PublicBasicTabView> {
  final _formKey = GlobalKey<FormState>();
  final _locationController = TextEditingController();
  
  String? _gender;
  bool _genderValidationError = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profileProvider = Provider.of<ProfileProvider>(context, listen: false);

      if (profileProvider.gender != null){
        setState(() {
          _gender = profileProvider.gender;
        });
      }

      if (profileProvider.location != null) {
        _locationController.text = profileProvider.location!;
      }

    });
  }

  Future<void> _submit() async {
    try{
      
      setState((){
          _genderValidationError = false;
      });

      if (!_formKey.currentState!.validate()) return;
      
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final profileProvider = Provider.of<ProfileProvider>(context, listen: false);

      if (authProvider.token == null) return;

      if (_gender == null){
        setState((){
          _genderValidationError = true;
        });
        return;
      }

      bool success = false;
      success = await profileProvider.updatePublicBasic(authProvider.token, _gender, _locationController.text);

      if (success) {
        await profileProvider.loadProfile(authProvider.token);
        CommonWidgets.showSnackBar(context, 'Update successful', isError: false);
      }
      
    } catch (e) {
        CommonWidgets.showSnackBar(context, 'Exception: $e', isError: true);
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

                    const Text(
                      'Gender',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    
                    if (_genderValidationError) ...[
                        Padding(
                          padding: EdgeInsets.only(left: 16.0),
                          child: Text(
                            'Please select gender',
                            style: TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ),
                    ],

                    RadioListTile<String>(
                      title: const Text('Male'),
                      value: 'male',
                      groupValue: _gender,
                      onChanged: (value) {
                        setState(() {
                          _gender = value;
                        });
                      },
                    ),
                    RadioListTile<String>(
                      title: const Text('Female'),
                      value: 'female',
                      groupValue: _gender,
                      onChanged: (value) {
                        setState(() {
                          _gender = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    AppTextField(
                    controller: _locationController,
                    labelText: 'Current Location',
                    obscureText: false,
                    validator: (v) => v?.isEmpty ?? true ? 'Please enter a location' : 
                              v!.length > 50 ? 'Location maximum 50 characters' : null,
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
