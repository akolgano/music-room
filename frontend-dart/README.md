# music_room

Music, Collaboration and mobility

## running app
adb reverse tcp:8000 tcp:8000; flutter run;

## VAR

Fetch from slack

## CURL Commands for Testing Music Room API

check swagger

## Folder structure

- (lib/core/): Contains fundamental app utilities and configuration.
- (lib/models/): Data structures and API request/response models using DIO
- (lib/providers/): State management using Provider pattern https://pub.dev/packages/provider
- (lib/services/): Business logic and external service integration
- (lib/screens/): UI screens organized by features
- (lib/widgets/): Reusable UI components

## Test Users

- username: admin
- password: admin
- username: testuser
- password: testpassword
- username: jane
- password: abc123
- username: anna
- password: Pass1234!

## TODO

### Mobile Application Setup

- Choose platform: Android Kotlin via flutter
- Make backend address configurable for testing
- Implement application as "remote control" to backend

### User Authentication & Account Management

- Create first-time user registration flow
- Implement mail/password registration option
- Implement social network registration (Facebook OR Google)
- Add social network account linking (Facebook/Google)
- Implement mail validation for mail/password accounts
- Add password reset functionality for mail/password accounts

### User Profile Management

- Create profile interface for updating:
    - Public information
    - Friend-only information
    - Private information
    - Music preferences

### Music Track Vote Service

- Create live music voting interface
- Implement track suggestion functionality
- Add voting mechanism for tracks
- Display playlist with vote-based ordering
- Implement visibility management (Public/Private events)
- Add license management UI:
    - Default: everyone can vote
    - License: only invited people can vote
    - License: location + time-based voting restrictions

### Music Playlist Editor Service

- Create real-time collaborative playlist editor
- Implement multi-user editing interface
- Add visibility management (Public/Private playlists)
- Implement license management:
    - Default: everyone can edit
    - License: only invited users can edit
- Handle concurrent editing conflicts

### Social Network Integration

- Integrate Facebook SDK for authentication
- Integrate Google SDK for authentication
- Handle social network login flows

# Technical Requirements

- Ensure all user actions are possible from mobile application
- Handle competition/concurrency issues in UI
- Implement proper error handling and user feedback
