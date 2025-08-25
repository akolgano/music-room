import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../providers/friend_providers.dart';
import '../../widgets/app_widgets.dart';
import '../../core/theme_core.dart';
import '../../core/provider_core.dart';
import '../base_screens.dart';

class AddFriendScreen extends StatefulWidget {
  const AddFriendScreen({super.key});

  @override
  State<AddFriendScreen> createState() => _AddFriendScreenState();
}

class _AddFriendScreenState extends BaseScreen<AddFriendScreen> {
  final _userIdController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  String get screenTitle => 'Add New Friend';

  @override
  List<Widget> get actions => [TextButton.icon(
    onPressed: () => navigateTo(AppRoutes.friendRequests),
    icon: const Icon(Icons.inbox, color: AppTheme.primary),
    label: const Text('Requests', style: TextStyle(color: AppTheme.primary)),
  )];

  @override
  void dispose() { _userIdController.dispose(); super.dispose(); }

  String? _validateUuid(String? v) => v?.trim().isEmpty ?? true ? 'Please enter a user ID'
    : !RegExp(r'^[0-9a-fA-F]{8}(-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}$').hasMatch(v!.trim()) ? 'Invalid UUID' : null;

  Widget _buildButton(String text, VoidCallback? onPressed, IconData icon, [bool isLoading = false]) =>
    SizedBox(width: double.infinity, child: AppWidgets.primaryButton(
      context: context, text: text, onPressed: onPressed, icon: icon, isLoading: isLoading));

  @override
  Widget buildContent() => SingleChildScrollView(
    padding: const EdgeInsets.all(4),
    child: Column(children: [
      AppTheme.buildFormCard(
        title: 'Add Friend by User ID', 
        titleIcon: Icons.person_add,
        child: Form(
          key: _formKey,
          child: Column(children: [
            AppWidgets.textField(
              context: context,
              controller: _userIdController, 
              labelText: 'User ID',
              hintText: 'e.g., 4270552b-1e03-4f35-980c-723b52b91d10',
              prefixIcon: Icons.person_search,
              validator: _validateUuid,
              onChanged: (value) => setState(() {}),
              onFieldSubmitted: kIsWeb ? (_) => _sendFriendRequest() : null,
            ),
            const SizedBox(height: 16),
            buildConsumerContent<FriendProvider>(
              builder: (context, fp) => Column(children: [
                if (_userIdController.text.trim().isNotEmpty) ...[
                  _buildButton('View Profile', () => Navigator.pushNamed(context, AppRoutes.userPage,
                    arguments: {'userId': _userIdController.text.trim(), 'username': null}), Icons.person),
                  const SizedBox(height: 12)],
                _buildButton(fp.isLoading ? 'Sending...' : 'Send Request',
                  _userIdController.text.trim().isNotEmpty && !fp.isLoading ? _sendFriendRequest : null,
                  Icons.send, fp.isLoading)]),
            ),
          ]),
        ),
      ),
      const SizedBox(height: 16)]));

  Future<void> _sendFriendRequest() async {
    if (!_formKey.currentState!.validate()) return;
    final userId = _userIdController.text.trim();
    if (userId == auth.userId) return showError('You cannot add yourself as a friend');
    await runAsyncAction(() async {
      final fp = getProvider<FriendProvider>();
      await Future.wait([fp.fetchFriends(auth.token!), fp.fetchReceivedInvitations(auth.token!),
        fp.fetchSentInvitations(auth.token!)]);
      if (fp.friends.any((f) => f.id == userId)) throw Exception('Already your friend');
      final pending = 'pending';
      if (fp.sentInvitations.any((i) => fp.getToUserId(i) == userId && fp.getInvitationStatus(i) == pending))
        throw Exception('Request already sent');
      if (fp.receivedInvitations.any((i) => fp.getFromUserId(i) == userId && fp.getInvitationStatus(i) == pending))
        throw Exception('User sent you a request. Check pending.');
      if (!await fp.sendFriendRequest(auth.token!, userId)) throw Exception(fp.errorMessage ?? 'Failed');
      _userIdController.clear();
    }, successMessage: 'Friend request sent successfully!');
  }
}