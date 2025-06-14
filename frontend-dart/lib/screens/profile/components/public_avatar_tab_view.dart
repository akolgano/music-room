// lib/screens/profile/components/public_avatar_tab_view.dart
import 'package:flutter/material.dart';
import '../../../core/app_core.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../../../providers/profile_provider.dart';
import '../../../providers/auth_provider.dart';
import 'package:provider/provider.dart';
import '../../../widgets/common_widgets.dart';
import 'package:mime/mime.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';


class PublicAvatarTabView extends StatefulWidget {
  const PublicAvatarTabView({Key? key}) : super(key: key);

  @override
  State<PublicAvatarTabView> createState() => _PublicAvatarTabViewState();
}

class _PublicAvatarTabViewState extends State<PublicAvatarTabView> {
  XFile? _imageFile;
  String? _imageBase64;
  Uint8List? _imageBytes;
  String? _mimeType;

  final String _baseUrl = dotenv.env['API_BASE_URL'] ?? AppConstants.defaultApiBaseUrl;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {

      if(!await isValidImageFile(picked)) {
          CommonWidgets.showSnackBar(context, 'Error: Need image JPEG or PNG', backgroundColor: Colors.red);
        return ;
      }

      final mimeType = await getMimeType(picked);
      final bytes = await picked.readAsBytes();

      setState(() {
        _imageBytes = bytes;
        _imageFile = picked;
        _imageBase64 = base64Encode(bytes);
        _mimeType = mimeType;

      });
    }
  }

  Future<bool> isValidImageFile(XFile file) async {
    final ext = file.name.split('.').last.toLowerCase();
    if (!(ext == 'jpg' || ext == 'jpeg' || ext == 'png')) {
      return false;
    }

    final bytes = await file.readAsBytes();
    final mimeType = lookupMimeType(file.name, headerBytes: bytes);
    return mimeType == 'image/jpeg' || mimeType == 'image/png';
  }

  Future<String?> getMimeType(XFile file) async {
    Uint8List bytes = await file.readAsBytes();

    final mimeType = lookupMimeType(file.name, headerBytes: bytes);
    return mimeType;
  }

  Future<void> clear() async{
      setState(() {
        _imageFile = null;
        _imageBytes = null;
        _imageBase64 = null;
        _mimeType = null;
      });
  }


  Future<void> _uploadImage() async {
    try{

      if (_imageFile == null) return;

      final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      bool success = false;
      success = await profileProvider.updateAvatar(authProvider.token, _imageBase64, _mimeType);

      if (success) {

        await clear();
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
              child: Column(
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

                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: _imageBytes != null
                        ? MemoryImage(_imageBytes!)
                        : (profileProvider.avatar != null
                            ? NetworkImage('$_baseUrl${profileProvider.avatar!}')
                            : null),
                    child: _imageBytes == null && profileProvider.avatar == null
                        ? Icon(Icons.person, size: 50)
                        : null,
                  ),
                  const SizedBox(height: 16),

                  ElevatedButton(
                    onPressed: _pickImage,
                    child: Text('Select Image'),
                  ),
                  const SizedBox(height: 16),

                  if (_imageBytes != null) ...[
                    ElevatedButton(
                      onPressed: _uploadImage,
                      child: Text('Save'),
                    ),
                  ],

                  const SizedBox(height: 16),

                ],
              ),
            ),
          ),
        ]
      );

      }
    );
  }
}
