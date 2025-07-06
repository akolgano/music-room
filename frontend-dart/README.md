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

## Playlist management workflow

### Playlist Dashboard
1. Load user's playlists → GET /playlists/saved_playlists/
2. Load public playlists → GET /playlists/public_playlists/
3. Display in tabs/sections with filtering options

### Create New Playlist
1. User clicks "Create Playlist"
2. Modal/form with name, description, visibility
3. Submit -> POST /playlists/playlists
4. Redirect to new playlist or refresh list

### View Playlist
1. User clicks on playlist -> GET /playlists/playlists/{playlist_id}
2. Load playlist tracks -> GET /playlists/playlist/{playlist_id}/tracks/
3. Display playlist info and track list
4. Setup WebSocket connection for real-time updates

### Real-time Playlist Updates
1. Establish WebSocket connection -> WS /ws/playlists/{playlist_id}/
2. Listen for playlist_update events
3. Update UI when tracks are added/removed/reordered
4. Update vote counts in real-time
5. Handle connection errors and reconnection

### Add Tracks to Playlist
1. From search results or track browser
2. Click "Add to Playlist" -> POST /playlists/{playlist_id}/add/
3. Update local playlist state
4. WebSocket will broadcast to other users

### Remove Tracks from Playlist
1. Click "Remove" on track -> POST /playlists/playlists/{playlist_id}/remove_tracks
2. Update local state
3. WebSocket broadcasts change

### Reorder Playlist Tracks
1. Drag and drop tracks in playlist
2. Calculate range_start, insert_before, range_length
3. Submit -> POST /playlists/{playlist_id}/move-track/
4. Update UI optimistically
5. WebSocket confirms change to other users

### Vote for Tracks
1. User clicks vote button -> POST /playlists/{playlist_id}/tracks/vote/
2. Update vote count locally
3. Disable vote button for that track
4. WebSocket broadcasts vote update

### Playlist Settings

#### Change Visibility:
1. Toggle public/private → POST /playlists/{playlist_id}/change-visibility/

#### Update License Settings:
1. Modify license options → PATCH /playlists/{playlist_id}/license/
2. Handle location permissions if location-based license

#### Invite Users:
1. Select friends → POST /playlists/{playlist_id}/invite-user/
2. Update invited users list
