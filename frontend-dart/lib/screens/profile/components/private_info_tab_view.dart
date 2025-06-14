// lib/screens/profile/components/private_info_tab_view.dart
import 'package:flutter/material.dart';
import '../../../core/app_core.dart';
import '../../../providers/profile_provider.dart';
import '../../../providers/auth_provider.dart';
import 'package:provider/provider.dart';
import '../../../widgets/common_widgets.dart';


class PrivateInfoTabView extends StatefulWidget {
  const PrivateInfoTabView({Key? key}) : super(key: key);

  @override
  State<PrivateInfoTabView> createState() => _PrivateInfoTabViewState();
}

class _PrivateInfoTabViewState extends State<PrivateInfoTabView> {
  final _formKey = GlobalKey<FormState>();
  final _lastNameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _streetController = TextEditingController();
  final _postalCodeController = TextEditingController();
  
  String? _selectedCountry;
  
  final List<String> _countries = [
    'Singapore',
    'Malaysia',
    'Indonesia',
    'Thailand',
    'United States',
    'Canada',
    'United Kingdom',
    'Australia',
  ];
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
      
      if (profileProvider.lastName != null) {
        _lastNameController.text = profileProvider.lastName!;
      }
      if (profileProvider.firstName != null) {
        _firstNameController.text = profileProvider.firstName!;
      }
      if (profileProvider.phone != null) {
        _phoneController.text = profileProvider.phone!;
      }
      if (profileProvider.street != null) {
        _streetController.text = profileProvider.street!;
      }
      if (profileProvider.country != null) {
        setState(() {
          _selectedCountry = profileProvider.country;
        });
      }
      if (profileProvider.postalCode != null) {
        _postalCodeController.text = profileProvider.postalCode!;
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
      success = await profileProvider.updatePrivateInfo(authProvider.token, _firstNameController.text, 
        _lastNameController.text, _phoneController.text, _streetController.text, _selectedCountry, 
        _postalCodeController.text);

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

                    AppTextField(
                      controller: _firstNameController,
                      labelText: 'First name',
                      obscureText: false,
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Please enter your first name';
                        } else if (v.length > 50) {
                          return 'First name maximum 50 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    AppTextField(
                      controller: _lastNameController,
                      labelText: 'Last name',
                      obscureText: false,
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Please enter your last name';
                        } else if (v.length > 50) {
                          return 'Last name maximum 50 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    AppTextField(
                      controller: _phoneController,
                      labelText: 'Phone number',
                      obscureText: false,
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Please enter a phone number';
                        } else if (!RegExp(r'^\d+$').hasMatch(v)) {
                          return 'Phone number must contain only digits';
                        } else if (v.length > 10) {
                          return 'Phone number maximum 10 digits';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    AppTextField(
                      controller: _streetController,
                      labelText: 'Street/Block/Unit/City',
                      obscureText: false,
                      minLines: 3,
                      maxLines: 5,
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Please enter your address';
                        } else if (v.length > 100) {
                          return 'Street/Block/Unit/City maximum 100 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      value: _selectedCountry,
                      decoration: InputDecoration(
                        labelText: 'Country',
                        border: OutlineInputBorder(),
                      ),
                      items: _countries.map((country) {
                        return DropdownMenuItem<String>(
                          value: country,
                          child: Text(country),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCountry = value;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a country';
                        }
                        return null;
                      },
                  ),
                  const SizedBox(height: 16),

                  AppTextField(
                      controller: _postalCodeController,
                      labelText: 'Postal Code',
                      obscureText: false,
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Please enter a postal code';
                        } else if (!RegExp(r'^\d+$').hasMatch(v)) {
                          return 'Postal code must contain only digits';
                        } else if (v.length > 10) {
                          return 'Postal code maximum 10 digits';
                        }
                        return null;
                      },
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
