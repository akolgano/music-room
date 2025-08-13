# music_room

Music, Collaboration and mobility

## running app
adb reverse tcp:8000 tcp:8000; flutter run;

## .env

Fetch from slack

## CURL Commands for Testing Music Room API

check swagger, can be fetched from user profile admin page 

## Test Users

- username: admin
- password: admin
- username: anna elina elana
- password: Pass1234!

## Code Details

### Core Architecture (lib/core/)

  - App Entry Point: main.dart - Application initialization and error handling
  - Routing & Navigation: builder_core.dart - Route generation and authentication guards
  - Dependency Injection: locator_core.dart - Service locator pattern
  - Theme Management: theme_core.dart - Centralized styling and theming
  - Constants: constants_core.dart - App-wide configuration values

### State Management (lib/providers/)

  - Authentication: auth_providers.dart - Login, social auth, token management
  - Music: music_providers.dart - Playlist and track data management
  - Friends: friend_providers.dart - Social features and friend management
  - Profile: profile_providers.dart - User profile data
  - Voting: voting_providers.dart - Real-time voting functionality

### Authentication (screens/auth/)

  - Login/Register: auth_screens.dart - Main authentication screen
  - Social Login: auth_screens.dart - Google/Facebook integration
  - Password Recovery: auth_screens.dart - Forgot password dialog

### Music Features (screens/playlists/, screens/music/)

  - Playlist Management: main_playlists.dart - Browse all playlists
  - Music Search: search_music.dart - Track discovery
  - Playlist Editor: editor_playlists.dart - Real-time collaborative editing
  - Voting System: Integrated playlist voting functionality

### Home & Navigation (screens/home/)

  - Main Interface: home_screens.dart - Tab-based navigation
  - Responsive Layout: home_screens.dart - Adaptive UI for different screen sizes

### Social Features (screens/friends/)

  - Friend Management: add_friends.dart, list_friends.dart, request_friends.dart
  - User Profiles: profile_screens.dart

### Services Layer (lib/services/)

  - API Communication: api_services.dart - REST API client
  - Music Player: player_services.dart - Audio playback control
  - WebSocket: websocket_services.dart - Real-time updates
  - Authentication: auth_services.dart - Auth token management
  - Notifications: notification_services.dart - Push notifications

### UI Components (lib/widgets/)

  - Core Widgets: app_widgets.dart - Cards, buttons, forms
  - Music Player: player_widgets.dart - Playback controls
  - Voting: votes_widgets.dart - Voting interface components
  - Forms: form_widgets.dart - Input validation and forms

1. Music Track Vote (IV.2.1)

  - Voting UI: votes_widgets.dart - Real-time voting components
  - State Management: voting_providers.dart - Vote synchronization
  - WebSocket Updates: websocket_services.dart - Live vote updates

2. Music Control Delegation (IV.2.2)

  - Player Service: player_services.dart - Centralized playback control
  - Permission System: Integrated with user authentication

3. Music Playlist Editor (IV.2.3)

  - Collaborative Editing: editor_playlists.dart - Multi-user playlist creation
  - Real-time Sync: WebSocket-based collaboration
  - Sharing Features: sharing_playlists.dart - Privacy controls

4. Social Authentication (IV.1)

  - OAuth Integration: auth_screens.dart - Google/Facebook login buttons
  - Social Linking: social_profile.dart - Account management

### Authentication Flow

  1. Route Protection: builder_core.dart - Guards protected routes (web)
  2. Token Management: Automatic token validation and refresh
  3. Social Login: auth_screens.dart - Integrated OAuth providers

### Responsive Design

  - Breakpoint System: main.dart - Mobile/tablet/desktop breakpoints
  - Adaptive Navigation: home_screens.dart - Rail vs bottom navigation
  - Screen Utilities: responsive_core.dart - Responsive helper functions
