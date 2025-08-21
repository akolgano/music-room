from rest_framework import serializers


#shared
class ErrorResponseSerializer(serializers.Serializer):
    error = serializers.CharField()

class UnauthorizedResponseSerializer(serializers.Serializer):
    detail = serializers.CharField()

class ErrorDetailSerializer(serializers.Serializer):
    detail = serializers.CharField()


#create_new_playlist
class PlaylistCreateRequestSerializer(serializers.Serializer):
    name = serializers.CharField()
    description = serializers.CharField(required=False, allow_blank=True)
    public = serializers.BooleanField(required=False, default=True)
    license_type = serializers.CharField(required=False, default='open')


class PlaylistCreateResponseSerializer(serializers.Serializer):
    message = serializers.CharField()
    playlist_id = serializers.UUIDField()


#get_playlist_info
class TrackSerializer(serializers.Serializer):
    name = serializers.CharField()
    artist = serializers.CharField()


class SharedUserSerializer(serializers.Serializer):
    id = serializers.UUIDField()
    username = serializers.CharField()


class PlaylistInfoSerializer(serializers.Serializer):
    id = serializers.IntegerField()
    playlist_name = serializers.CharField()
    description = serializers.CharField()
    public = serializers.BooleanField()
    creator = serializers.CharField()
    license_type = serializers.CharField()
    tracks = TrackSerializer(many=True)
    shared_with = SharedUserSerializer(many=True)


class PlaylistInfoResponseSerializer(serializers.Serializer):
    playlist = PlaylistInfoSerializer(many=True)


#update_playlist
class PlaylistUpdateSerializer(serializers.Serializer):
    name = serializers.CharField(required=False)
    description = serializers.CharField(required=False)
    public = serializers.BooleanField(required=False)
    license_type = serializers.CharField(required=False)


class PlaylistUpdateResponseSerializer(serializers.Serializer):
    message = serializers.CharField()


#delete_playlist
class PlaylistDeleteResponseSerializer(serializers.Serializer):
    message = serializers.CharField()


#playlist_tracks
class PlaylistTrackSerializer(serializers.Serializer):
    track_id = serializers.IntegerField()
    playlist_track_id = serializers.IntegerField()
    deezer_track_id = serializers.IntegerField()
    name = serializers.CharField()
    position = serializers.IntegerField()
    points = serializers.IntegerField()

class PlaylistTracksResponseSerializer(serializers.Serializer):
    playlist = serializers.CharField()
    tracks = PlaylistTrackSerializer(many=True)


#add_track
class AddTrackRequestSerializer(serializers.Serializer):
    track_id = serializers.IntegerField()

class AddTrackSuccessSerializer(serializers.Serializer):
    status = serializers.CharField()
    track_id = serializers.IntegerField()


#move_track_in_playlist
class MoveTrackRequestSerializer(serializers.Serializer):
    range_start = serializers.IntegerField()
    insert_before = serializers.IntegerField()
    range_length = serializers.IntegerField()

class MoveTrackSuccessSerializer(serializers.Serializer):
    message = serializers.CharField()


#delete_track
class DeleteTrackRequestSerializer(serializers.Serializer):
    track_id = serializers.IntegerField()

class DeleteTrackSuccessSerializer(serializers.Serializer):
    message = serializers.CharField()


#get_user_saved_playlists
class TrackSerializer(serializers.Serializer):
    name = serializers.CharField()
    artist = serializers.CharField()

class PlaylistSerializer(serializers.Serializer):
    id = serializers.IntegerField()
    name = serializers.CharField()
    description = serializers.CharField(allow_blank=True, required=False)
    public = serializers.BooleanField()
    creator = serializers.CharField()
    tracks = TrackSerializer(many=True)

class UserSavedPlaylistsResponseSerializer(serializers.Serializer):
    playlists = PlaylistSerializer(many=True)


#get_all_shared_playlists
class SharedPlaylistsResponseSerializer(serializers.Serializer):
    playlists = PlaylistSerializer(many=True)


#change_visibility
class ChangeVisibilityRequestSerializer(serializers.Serializer):
    public = serializers.BooleanField()

class ChangeVisibilityResponseSerializer(serializers.Serializer):
    message = serializers.CharField()


#invite_user
class InviteUserRequestSerializer(serializers.Serializer):
    user_id = serializers.UUIDField()

class InviteUserResponseSerializer(serializers.Serializer):
    message = serializers.CharField()


#patch_playlist_license

#vote_for_track_schema
class VoteSerializer(serializers.Serializer):
    range_start = serializers.IntegerField()

class PlaylistTrackSerializer(serializers.Serializer):
    name = serializers.CharField()
    artist = serializers.CharField()
    points = serializers.IntegerField()

class PlaylistDataSerializer(serializers.Serializer):
    id = serializers.IntegerField()
    playlist_name = serializers.CharField()
    description = serializers.CharField(allow_blank=True, required=False)
    public = serializers.BooleanField()
    creator = serializers.CharField()
    tracks = PlaylistTrackSerializer(many=True)

class PlaylistResponseSerializer(serializers.Serializer):
    playlist = PlaylistDataSerializer()

