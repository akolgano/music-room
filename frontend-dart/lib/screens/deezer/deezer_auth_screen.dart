import 'package:flutter/material.dart';
import '../../core/core.dart';
import '../../widgets/widgets.dart';
import '../../services/deezer_service.dart';
import '../base_screen.dart';

class DeezerAuthScreen extends StatefulWidget {
  const DeezerAuthScreen({super.key});

  @override
  State<DeezerAuthScreen> createState() => _DeezerAuthScreenState();
}

class _DeezerAuthScreenState extends BaseScreen<DeezerAuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _arlController = TextEditingController();
  bool _isLoading = false;

  @override
  String get screenTitle => 'Deezer Authentication';

  @override
  Widget buildContent() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppWidgets.infoBanner(
              title: 'Enable Full Audio Playback',
              message: 'Connect your Deezer account to play full tracks instead of 30-second previews.',
              icon: Icons.music_note,
              color: AppTheme.primary,
            ),
            const SizedBox(height: 24),
            
            _buildInstructionsCard(),
            const SizedBox(height: 24),
            
            _buildArlInputSection(),
            const SizedBox(height: 32),
            
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionsCard() {
    return Card(
      color: AppTheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.info_outline, color: AppTheme.primary, size: 20),
                SizedBox(width: 8),
                Text(
                  'How to get your ARL token',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInstructionStep('1.', 'Open Deezer in your web browser and log in'),
            _buildInstructionStep('2.', 'Press F12 to open Developer Tools'),
            _buildInstructionStep('3.', 'Go to Application > Cookies > deezer.com'),
            _buildInstructionStep('4.', 'Find the "arl" cookie and copy its value'),
            _buildInstructionStep('5.', 'Paste the ARL token below'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Note: ARL tokens expire after ~3 months and need to be refreshed.',
                      style: TextStyle(color: Colors.orange, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionStep(String number, String instruction) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 20,
            child: Text(
              number,
              style: const TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              instruction,
              style: const TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArlInputSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ARL Token',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        AppWidgets.textField(
          context: context,
          controller: _arlController,
          labelText: 'Enter your Deezer ARL token',
          obscureText: true,
        ),
        const SizedBox(height: 8),
        const Text(
          'This token will be stored securely on your device for authentication with Deezer.',
          style: TextStyle(
            fontSize: 12,
            color: Colors.white60,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _authenticateWithDeezer,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.black,
                    ),
                  )
                : const Text(
                    'Connect Deezer Account',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        if (DeezerService.instance.isInitialized) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Deezer account connected! You can now play full audio tracks.',
                    style: TextStyle(color: Colors.green, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _disconnectDeezer,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Disconnect Deezer Account'),
            ),
          ),
        ],
        const SizedBox(height: 24),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Skip for now (use preview audio only)',
            style: TextStyle(color: Colors.white60),
          ),
        ),
      ],
    );
  }

  Future<void> _authenticateWithDeezer() async {
    final arl = _arlController.text.trim();
    
    if (arl.isEmpty) {
      showError('Please enter your ARL token');
      return;
    }
    
    if (arl.length < 50) {
      showError('ARL token appears to be invalid (too short)');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success = await DeezerService.instance.initialize(arl: arl);

      if (success) {
        showSuccess('Deezer account connected successfully!');
        
        if (mounted) {
          Navigator.pop(context, true);
        }
      } else {
        showError('Failed to connect to Deezer. Please check your ARL token.');
      }
    } catch (e) {
      showError('Authentication failed: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _disconnectDeezer() {
    DeezerService.instance.dispose();
    showSuccess('Deezer account disconnected');
    setState(() {});
  }

  @override
  void dispose() {
    _arlController.dispose();
    super.dispose();
  }
}
