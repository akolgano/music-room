// lib/screens/docs/api_docs_screen.dart
import 'package:flutter/material.dart';

class ApiDocsScreen extends StatelessWidget {
  const ApiDocsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Music Room API Documentation'),
      ),
      body: DefaultTabController(
        length: 6,
        child: Column(
          children: [
            const TabBar(
              labelColor: Colors.indigo,
              tabs: [
                Tab(text: 'Authentication'),
                Tab(text: 'Playlists'),
                Tab(text: 'Tracks'),
                Tab(text: 'Events & Voting'),
                Tab(text: 'Deezer'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildAuthDocs(),
                  _buildPlaylistDocs(),
                  _buildTrackDocs(),
                  _buildEventDocs(),
                  _buildDeezerDocs(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthDocs() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Authentication APIs',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildEndpointCard(
            title: 'User Registration',
            endpoint: '/users/signup/',
            method: 'POST',
            description: 'Register a new user account',
            requestParams: '''
{
  "username": "string", // Required, min length 1, max length 20
  "email": "string",    // Required, valid email format
  "password": "string"  // Required, min length 8
}''',
            responseFormat: '''
{
  "token": "string",
  "user": {
    "id": "integer",
    "username": "string",
    "email": "string"
  }
}''',
            isImplemented: true,
          ),
          
          _buildEndpointCard(
            title: 'User Login',
            endpoint: '/users/login/',
            method: 'POST',
            description: 'Authenticate a user and receive an auth token',
            requestParams: '''
{
  "username": "string",
  "password": "string"
}''',
            responseFormat: '''
{
  "token": "string",
  "user": {
    "id": "integer",
    "username": "string",
    "email": "string"
  }
}''',
            isImplemented: true,
          ),
          
          _buildEndpointCard(
            title: 'User Logout',
            endpoint: '/users/logout/',
            method: 'POST',
            description: 'Logout and invalidate the user token',
            requestParams: '''
{
  "username": "string"
}

Headers:
Authorization: Token <token>''',
            responseFormat: '''
"Logout successfully"''',
            isImplemented: true,
          ),
          
          _buildEndpointCard(
            title: 'Forgot Password',
            endpoint: '/users/forgot_password/',
            method: 'POST',
            description: 'Send password reset email to user',
            requestParams: '''
{
  "email": "string"
}''',
            responseFormat: '''
{
  "message": "Password reset email sent"
}''',
            isImplemented: false,
          ),
          
          _buildEndpointCard(
            title: 'Reset Password',
            endpoint: '/users/reset_password/',
            method: 'POST',
            description: 'Reset password using token sent via email',
            requestParams: '''
{
  "token": "string",
  "password": "string"
}''',
            responseFormat: '''
{
  "message": "Password updated successfully"
}''',
            isImplemented: false,
          ),
          
          _buildEndpointCard(
            title: 'User Profile',
            endpoint: '/users/profile/',
            method: 'GET',
            description: 'Get user profile information',
            requestParams: '''
Headers:
Authorization: Token <token>''',
            responseFormat: '''
{
  "id": "integer",
  "username": "string",
  "email": "string",
  "public_info": "object",
  "friends_only_info": "object",
  "private_info": "object",
  "music_preferences": "object"
}''',
            isImplemented: false,
          ),
          
          _buildEndpointCard(
            title: 'Update User Profile',
            endpoint: '/users/profile/',
            method: 'PUT',
            description: 'Update user profile information',
            requestParams: '''
{
  "public_info": "object",  // Optional
  "friends_only_info": "object",  // Optional
  "private_info": "object",  // Optional
  "music_preferences": "object"  // Optional
}

Headers:
Authorization: Token <token>''',
            responseFormat: '''
{
  "id": "integer",
  "username": "string",
  "email": "string",
  "public_info": "object",
  "friends_only_info": "object",
  "private_info": "object",
  "music_preferences": "object"
}''',
            isImplemented: false,
          ),
          
          _buildEndpointCard(
            title: 'Link Social Account',
            endpoint: '/users/link_social/',
            method: 'POST',
            description: 'Link a social network account (Facebook or Google)',
            requestParams: '''
{
  "provider": "string",  // "facebook" or "google"
  "access_token": "string"
}

Headers:
Authorization: Token <token>''',
            responseFormat: '''
{
  "message": "Social account linked successfully"
}''',
            isImplemented: false,
          ),
        ],
      ),
    );
  }

  Widget _buildPlaylistDocs() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Playlist APIs',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildEndpointCard(
            title: 'Create Playlist',
            endpoint: '/playlists/playlists',
            method: 'POST',
            description: 'Create a new playlist',
            requestParams: '''
{
  "name": "string",
  "description": "string",
  "public": "boolean"
}

Headers:
Authorization: Token <token>''',
            responseFormat: '''
{
  "message": "Empty playlist is created.",
  "playlist_id": "integer"
}''',
            isImplemented: true,
          ),
          
          _buildEndpointCard(
            title: 'Create Playlist with Tracks',
            endpoint: '/playlists/save_playlist/',
            method: 'POST',
            description: 'Create a new playlist with tracks',
            requestParams: '''
{
  "name": "string",
  "description": "string",
  "public": "boolean",
  "track_ids": ["integer", "integer", ...]
}

Headers:
Authorization: Token <token>''',
            responseFormat: '''
{
  "message": "Playlist created and tracks added successfully.",
  "playlist_id": "integer",
  "tracks": ["integer", "integer", ...]
}''',
            isImplemented: true,
          ),
          
          _buildEndpointCard(
            title: 'Get User\'s Saved Playlists',
            endpoint: '/playlists/saved_playlists/',
            method: 'GET',
            description: 'Get all playlists saved by the user',
            requestParams: '''
Headers:
Authorization: Token <token>''',
            responseFormat: '''
{
  "playlists": [
    {
      "name": "string",
      "description": "string",
      "public": "boolean",
      "creator": "string",
      "tracks": [
        {
          "name": "string",
          "artist": "string"
        },
        ...
      ]
    },
    ...
  ]
}''',
            isImplemented: true,
          ),
          
          _buildEndpointCard(
            title: 'Get Public Playlists',
            endpoint: '/playlists/public_playlists/',
            method: 'GET',
            description: 'Get all public playlists',
            requestParams: 'None',
            responseFormat: '''
{
  "playlists": [
    {
      "name": "string",
      "description": "string",
      "public": "boolean",
      "creator": "string",
      "tracks": [
        {
          "name": "string",
          "artist": "string"
        },
        ...
      ]
    },
    ...
  ]
}''',
            isImplemented: true,
          ),
          
          _buildEndpointCard(
            title: 'Get Playlist Details',
            endpoint: '/playlists/playlists/{playlist_id}',
            method: 'GET',
            description: 'Get details for a specific playlist',
            requestParams: '''
Headers:
Authorization: Token <token>''',
            responseFormat: '''
{
  "playlist": [
    {
      "name": "string",
      "description": "string",
      "public": "boolean",
      "creator": "string",
      "tracks": [
        {
          "name": "string",
          "artist": "string"
        },
        ...
      ]
    }
  ]
}''',
            isImplemented: true,
          ),
          
          _buildEndpointCard(
            title: 'Update Playlist',
            endpoint: '/playlists/playlists/{playlist_id}',
            method: 'PUT',
            description: 'Update playlist details',
            requestParams: '''
{
  "name": "string",
  "description": "string",
  "public": "boolean"
}

Headers:
Authorization: Token <token>''',
            responseFormat: 'Success: 200 OK',
            isImplemented: true,
          ),
          
          _buildEndpointCard(
            title: 'Delete Playlist',
            endpoint: '/playlists/playlists/{playlist_id}',
            method: 'DELETE',
            description: 'Delete a playlist',
            requestParams: '''
Headers:
Authorization: Token <token>''',
            responseFormat: 'Success: 204 No Content',
            isImplemented: true,
          ),
          
          _buildEndpointCard(
            title: 'Add Tracks to Playlist',
            endpoint: '/playlists/playlists/{playlist_id}/tracks',
            method: 'POST',
            description: 'Add multiple tracks to a playlist',
            requestParams: '''
{
  "track_ids": ["integer", "integer", ...]
}

Headers:
Authorization: Token <token>''',
            responseFormat: '''
{
  "message": "Tracks added successfully.",
  "playlist_id": "integer",
  "tracks": ["integer", "integer", ...]
}''',
            isImplemented: true,
          ),
          
          _buildEndpointCard(
            title: 'Add Single Track to Playlist',
            endpoint: '/playlists/to_playlist/{playlist_id}/add_track/{track_id}/',
            method: 'POST',
            description: 'Add a single track to a playlist',
            requestParams: '''
Headers:
Authorization: Token <token>''',
            responseFormat: '''
{
  "message": "Track added to playlist successfully.",
  "playlist_id": "integer",
  "track_id": "integer"
}''',
            isImplemented: true,
          ),
          
          _buildEndpointCard(
            title: 'Remove Tracks from Playlist',
            endpoint: '/playlists/{playlist_id}/remove_tracks',
            method: 'POST',
            description: 'Remove tracks from a playlist',
            requestParams: '''
{
  "track_ids": ["integer", "integer", ...]
}

Headers:
Authorization: Token <token>''',
            responseFormat: '''
{
  "message": "Tracks deleted successfully.",
  "playlist_id": "integer",
  "tracks": ["integer", "integer", ...]
}''',
            isImplemented: true,
          ),
          
          _buildEndpointCard(
            title: 'Collaborative Editing Status',
            endpoint: '/playlists/{playlist_id}/collaborative_status',
            method: 'GET',
            description: 'Get real-time editing status of a playlist',
            requestParams: '''
Headers:
Authorization: Token <token>''',
            responseFormat: '''
{
  "editors": [
    {
      "user_id": "integer",
      "username": "string",
      "current_action": "string"
    },
    ...
  ]
}''',
            isImplemented: false,
          ),
        ],
      ),
    );
  }

  Widget _buildTrackDocs() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Track APIs',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildEndpointCard(
            title: 'Search Tracks',
            endpoint: '/tracks/search/',
            method: 'GET',
            description: 'Search for tracks in the database',
            requestParams: '''
query: "string" (query parameter)''',
            responseFormat: '''
{
  "tracks": [
    {
      "id": "integer",
      "name": "string",
      "artist": "string",
      "album": "string",
      "url": "string",
      "deezer_track_id": "string"
    },
    ...
  ]
}''',
            isImplemented: true,
          ),
          
          _buildEndpointCard(
            title: 'Add Track from Deezer',
            endpoint: '/tracks/add_from_deezer/{track_id}/',
            method: 'POST',
            description: 'Add a track from Deezer to the local database',
            requestParams: '''
Headers:
Authorization: Token <token>''',
            responseFormat: '''
{
  "message": "Track added successfully." or "Track already exists."
}''',
            isImplemented: true,
          ),
          
          _buildEndpointCard(
            title: 'Get Track Details',
            endpoint: '/tracks/{track_id}/',
            method: 'GET',
            description: 'Get detailed information about a track',
            requestParams: 'None',
            responseFormat: '''
{
  "id": "integer",
  "name": "string",
  "artist": "string",
  "album": "string",
  "url": "string",
  "deezer_track_id": "string",
  "preview_url": "string"
}''',
            isImplemented: false,
          ),
        ],
      ),
    );
  }

  Widget _buildEventDocs() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Events & Voting APIs (Music Track Vote)',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildEndpointCard(
            title: 'Create Music Event',
            endpoint: '/events/',
            method: 'POST',
            description: 'Create a new music event with voting',
            requestParams: '''
{
  "name": "string",
  "description": "string",
  "public": "boolean",
  "location": "string",  // Optional
  "start_time": "datetime",
  "end_time": "datetime",
  "initial_playlist_id": "integer"  // Optional
}

Headers:
Authorization: Token <token>''',
            responseFormat: '''
{
  "event_id": "integer",
  "name": "string",
  "description": "string",
  "public": "boolean",
  "location": "string",
  "start_time": "datetime",
  "end_time": "datetime",
  "creator": "string"
}''',
            isImplemented: false,
          ),
          
          _buildEndpointCard(
            title: 'Get Events',
            endpoint: '/events/',
            method: 'GET',
            description: 'Get all public events or events created by the user',
            requestParams: '''
Headers:
Authorization: Token <token>''',
            responseFormat: '''
{
  "events": [
    {
      "id": "integer",
      "name": "string",
      "description": "string",
      "public": "boolean",
      "location": "string",
      "start_time": "datetime",
      "end_time": "datetime",
      "creator": "string"
    },
    ...
  ]
}''',
            isImplemented: false,
          ),
          
          _buildEndpointCard(
            title: 'Get Event Details',
            endpoint: '/events/{event_id}/',
            method: 'GET',
            description: 'Get detailed information about an event',
            requestParams: '''
Headers:
Authorization: Token <token>''',
            responseFormat: '''
{
  "id": "integer",
  "name": "string",
  "description": "string",
  "public": "boolean",
  "location": "string",
  "start_time": "datetime",
  "end_time": "datetime",
  "creator": "string",
  "current_track": {
    "id": "integer",
    "name": "string",
    "artist": "string"
  },
  "playlist": {
    "id": "integer",
    "name": "string"
  }
}''',
            isImplemented: false,
          ),
          
          _buildEndpointCard(
            title: 'Update Event',
            endpoint: '/events/{event_id}/',
            method: 'PUT',
            description: 'Update event details',
            requestParams: '''
{
  "name": "string",  // Optional
  "description": "string",  // Optional
  "public": "boolean",  // Optional
  "location": "string",  // Optional
  "start_time": "datetime",  // Optional
  "end_time": "datetime"  // Optional
}

Headers:
Authorization: Token <token>''',
            responseFormat: '''
{
  "id": "integer",
  "name": "string",
  "description": "string",
  "public": "boolean",
  "location": "string",
  "start_time": "datetime",
  "end_time": "datetime",
  "creator": "string"
}''',
            isImplemented: false,
          ),
          
          _buildEndpointCard(
            title: 'Delete Event',
            endpoint: '/events/{event_id}/',
            method: 'DELETE',
            description: 'Delete an event',
            requestParams: '''
Headers:
Authorization: Token <token>''',
            responseFormat: 'Success: 204 No Content',
            isImplemented: false,
          ),
          
          _buildEndpointCard(
            title: 'Get Event Queue',
            endpoint: '/events/{event_id}/queue/',
            method: 'GET',
            description: 'Get the current track queue for an event',
            requestParams: '''
Headers:
Authorization: Token <token>''',
            responseFormat: '''
{
  "tracks": [
    {
      "id": "integer",
      "name": "string",
      "artist": "string",
      "votes": "integer"
    },
    ...
  ]
}''',
            isImplemented: false,
          ),
          
          _buildEndpointCard(
            title: 'Add Track to Event',
            endpoint: '/events/{event_id}/tracks/',
            method: 'POST',
            description: 'Add a track to an event queue',
            requestParams: '''
{
  "track_id": "integer"
}

Headers:
Authorization: Token <token>''',
            responseFormat: '''
{
  "message": "Track added to event queue",
  "track": {
    "id": "integer",
    "name": "string",
    "artist": "string",
    "votes": 1
  }
}''',
            isImplemented: false,
          ),
          
          _buildEndpointCard(
            title: 'Vote for Track',
            endpoint: '/events/{event_id}/tracks/{track_id}/vote/',
            method: 'POST',
            description: 'Vote for a track in an event queue',
            requestParams: '''
Headers:
Authorization: Token <token>''',
            responseFormat: '''
{
  "message": "Vote recorded",
  "track_id": "integer",
  "votes": "integer"
}''',
            isImplemented: false,
          ),
          
          _buildEndpointCard(
            title: 'Get Event Participants',
            endpoint: '/events/{event_id}/participants/',
            method: 'GET',
            description: 'Get a list of event participants',
            requestParams: '''
Headers:
Authorization: Token <token>''',
            responseFormat: '''
{
  "participants": [
    {
      "id": "integer",
      "username": "string",
      "votes_cast": "integer"
    },
    ...
  ]
}''',
            isImplemented: false,
          ),
          
          _buildEndpointCard(
            title: 'Invite Users to Event',
            endpoint: '/events/{event_id}/invite/',
            method: 'POST',
            description: 'Invite users to a private event',
            requestParams: '''
{
  "user_ids": ["integer", "integer", ...]
}

Headers:
Authorization: Token <token>''',
            responseFormat: '''
{
  "message": "Invitations sent",
  "invites": ["integer", "integer", ...]
}''',
            isImplemented: false,
          ),
        ],
      ),
    );
  }

  Widget _buildDeezerDocs() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Deezer Integration APIs',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildEndpointCard(
            title: 'Get Deezer Track',
            endpoint: '/deezer/track/{track_id}/',
            method: 'GET',
            description: 'Get track information from Deezer',
            requestParams: 'None',
            responseFormat: 'Deezer track JSON object',
            isImplemented: true,
          ),
          
          _buildEndpointCard(
            title: 'Search Deezer Tracks',
            endpoint: '/deezer/search/',
            method: 'GET',
            description: 'Search for tracks on Deezer',
            requestParams: '''
q: "string" (query parameter)''',
            responseFormat: 'Deezer search results JSON object',
            isImplemented: true,
          ),
        ],
      ),
    );
  }

  Widget _buildEndpointCard({
    required String title,
    required String endpoint,
    required String method,
    required String description,
    required String requestParams,
    required String responseFormat,
    required bool isImplemented,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getMethodColor(method),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                method,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (!isImplemented)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'FUTURE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Text(
          endpoint,
          style: const TextStyle(
            fontFamily: 'monospace',
            color: Colors.blue,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(description),
                const SizedBox(height: 16),
                const Text(
                  'Request Parameters:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  width: double.infinity,
                  child: Text(
                    requestParams,
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ),
                const Text(
                  'Response Format:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  width: double.infinity,
                  child: Text(
                    responseFormat,
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getMethodColor(String method) {
    switch (method.toUpperCase()) {
      case 'GET':
        return Colors.green;
      case 'POST':
        return Colors.blue;
      case 'PUT':
        return Colors.orange;
      case 'DELETE':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
