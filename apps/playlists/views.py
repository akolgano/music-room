import json
from rest_framework.decorators import api_view, authentication_classes, permission_classes
from django.http import JsonResponse
from .models import Playlist, Track
from apps.tracks.models import Track
from django.shortcuts import get_object_or_404
from rest_framework.authentication import TokenAuthentication
from rest_framework.permissions import IsAuthenticated
from apps.playlists.models import Playlist, PlaylistTrack
from django.db import models
from django.db import transaction
from channels.layers import get_channel_layer
from asgiref.sync import async_to_sync

@api_view(['POST'])
@authentication_classes([TokenAuthentication])
@permission_classes([IsAuthenticated])
def create_new_playlist(request):
    user = request.user
    name = request.data.get('name')
    description = request.data.get('description', '')
    public = request.data.get('public', True)
    public = True
    if not name:
        return JsonResponse({"error": "Playlist name is required."}, status=400)
    playlist = Playlist.objects.create(
        name=name,
        description=description,
        public=public,
        creator=user
    )
    user.saved_playlists.add(playlist)

    return JsonResponse({
        "message": "Empty playlist is created.",
        "playlist_id": playlist.id
    }, status=201)


@api_view(['GET'])
@authentication_classes([TokenAuthentication])
@permission_classes([IsAuthenticated])
def get_user_saved_playlists(request):
    user = request.user

    playlists = Playlist.objects.filter(users_saved=user)

    playlist_data = []
    for playlist in playlists:
        tracks = playlist.tracks.all()
        track_list = [{'name': pt.track.name, 'artist': pt.track.artist} for pt in tracks]

        playlist_data.append({
            'name': playlist.name,
            'description': playlist.description,
            'public': playlist.public,
            'creator': playlist.creator.username,
            'tracks': track_list,
        })

    return JsonResponse({'playlists': playlist_data})


@api_view(['GET'])
@authentication_classes([TokenAuthentication])
@permission_classes([IsAuthenticated])
def get_all_shared_playlists(request):

    playlists = Playlist.objects.filter(public=True)

    playlist_data = []
    for playlist in playlists:
        tracks = playlist.tracks.all()
        track_list = [{'name': track.name, 'artist': track.artist} for track in tracks]

        playlist_data.append({
            'name': playlist.name,
            'description': playlist.description,
            'public': playlist.public,
            'creator': playlist.creator.username,  # Show the creator of the playlist
            'tracks': track_list,
        })

    return JsonResponse({'playlists': playlist_data})


@api_view(['POST'])
@authentication_classes([TokenAuthentication])
@permission_classes([IsAuthenticated])
def save_shared_playlist(request):
    if not request.user.is_authenticated:
        return JsonResponse({"error": "Authentication required."}, status=401)

    user = request.user
    name = request.data.get('name')
    description = request.data.get('description', '')
    public = request.data.get('public', False)
    track_ids = request.data.get('track_ids', [])  # List of track IDs to associate with the playlist

    if not name:
        return JsonResponse({"error": "Playlist name is required."}, status=400)

    playlist = Playlist.objects.create(
        name=name,
        description=description,
        public=public,
        creator=user
    )

    tracks = Track.objects.filter(id__in=track_ids)

    if tracks.exists():
        playlist.tracks.add(*tracks)
    else:
        return JsonResponse({"error": "One or more tracks not found."}, status=404)

    user.saved_playlists.add(playlist)

    return JsonResponse({
        "message": "Playlist created and tracks added successfully.",
        "playlist_id": playlist.id,
        "tracks": [track.id for track in tracks]
    }, status=201)


@api_view(['POST'])
@authentication_classes([TokenAuthentication])
@permission_classes([IsAuthenticated])
def add_items_to_playlist(request, playlist_id):
    try:
        user = request.user
        playlist = get_object_or_404(Playlist, id=playlist_id)
        track_ids = request.data.get('track_ids', [])  
        tracks = Track.objects.filter(id__in=track_ids)

        if tracks.exists():
            playlist.tracks.add(*tracks)
        else:
            return JsonResponse({"error": "One or more tracks not found."}, status=404)

        user.saved_playlists.add(playlist)
        return JsonResponse({
            "message": "Tracks added successfully.",
            "playlist_id": playlist.id,
            "tracks": [track.id for track in tracks]
        }, status=201)
    except Playlist.DoesNotExist:
        return JsonResponse({"error": "Playlist not found."}, status=404)
    except Track.DoesNotExist:
        return JsonResponse({"error": "Track not found."}, status=404)


@api_view(['GET'])
@authentication_classes([TokenAuthentication])
@permission_classes([IsAuthenticated])
def get_playlist_info(request, playlist_id):
    try:
        user = request.user
        playlist = get_object_or_404(Playlist, id=playlist_id)


        playlist_data = []
        tracks = playlist.tracks.all()
        track_list = [{'name': pt.track.name, 'artist': pt.track.artist} for pt in tracks]

        playlist_data.append({
            'playlist_name': playlist.name,
            'description': playlist.description,
            'public': playlist.public,
            'creator': playlist.creator.username,
            'tracks': track_list,
        })

        return JsonResponse({'playlist': playlist_data})
    except Playlist.DoesNotExist:
        return JsonResponse({"error": "Playlist not found."}, status=404)


@api_view(['POST'])
@authentication_classes([TokenAuthentication])
@permission_classes([IsAuthenticated])
def remove_playlist_items(request, playlist_id):
    try:
        user = request.user
        playlist = get_object_or_404(Playlist, id=playlist_id)
        track_ids = request.data.get('track_ids', [])  
        tracks = Track.objects.filter(id__in=track_ids)

        if tracks.exists():
            playlist.tracks.remove(*tracks)
        else:
            return JsonResponse({"error": "One or more tracks not found."}, status=404)

        user.saved_playlists.add(playlist)
        return JsonResponse({
            "message": "Tracks deleted successfully.",
            "playlist_id": playlist.id,
            "tracks": [track.id for track in tracks]
        }, status=200)
    except Playlist.DoesNotExist:
        return JsonResponse({"error": "Playlist not found."}, status=404)
    except Track.DoesNotExist:
        return JsonResponse({"error": "Track not found."}, status=404)

@api_view(['GET'])
@authentication_classes([TokenAuthentication])
@permission_classes([IsAuthenticated])
def playlist_tracks(request, playlist_id):
    playlist = get_object_or_404(Playlist, id=playlist_id)
    tracks = PlaylistTrack.objects.filter(playlist=playlist).select_related('track')

    data = [{
        'track_id': pt.track.id,
        'name': pt.track.name,
        'position': pt.position,
    } for pt in tracks]

    return JsonResponse({'playlist': playlist.name, 'tracks': data})

@api_view(['POST'])
@authentication_classes([TokenAuthentication])
@permission_classes([IsAuthenticated])
def add_track(request, playlist_id):
    if request.method == "POST":
        playlist = get_object_or_404(Playlist, id=playlist_id)
        data = json.loads(request.body)

        track_id = data.get("track_id")
        track = get_object_or_404(Track, id=track_id)

        max_pos = PlaylistTrack.objects.filter(playlist=playlist).aggregate(models.Max('position'))['position__max'] or 0
        PlaylistTrack.objects.create(playlist=playlist, track=track, position=max_pos + 1)

        return JsonResponse({'status': 'track added'}, status=201)



@api_view(['POST'])
@authentication_classes([TokenAuthentication])
@permission_classes([IsAuthenticated])
def move_track_in_playlist(request):
    if request.method != 'POST':
        return JsonResponse({'error': 'Invalid method'}, status=405)

    try:
        print('move_track_in_playlist starts')
        data = json.loads(request.body)

        playlist_id = data['playlist_id']
        range_start = data['range_start']
        insert_before = data['insert_before']
        range_length = data.get('range_length', 1)

        playlist = Playlist.objects.get(id=playlist_id)
        tracks = list(PlaylistTrack.objects.filter(playlist=playlist).order_by('position'))

        moving_slice = tracks[range_start:range_start + range_length]
        if not moving_slice:
            return JsonResponse({'error': 'Invalid range'}, status=400)

        del tracks[range_start:range_start + range_length]

        if insert_before > range_start:
            insert_before -= range_length

        for i, track in enumerate(moving_slice):
            tracks.insert(insert_before + i, track)

        TEMP_OFFSET = 1000
        with transaction.atomic():
            for i, pt in enumerate(tracks):
                pt.position = i + TEMP_OFFSET
            PlaylistTrack.objects.bulk_update(tracks, ['position'])

            for i, pt in enumerate(tracks):
                pt.position = i
            PlaylistTrack.objects.bulk_update(tracks, ['position'])
        updated_playlist = Playlist.objects.get(id=playlist_id)
        utracks = list(PlaylistTrack.objects.filter(playlist=playlist).order_by('position'))
        data = [{"id": t.id, "position": t.position} for t in tracks]
        channel_layer = get_channel_layer()
        print(channel_layer)
        async_to_sync(channel_layer.group_send)(
            f'playlist_{playlist_id}',
            {
                'type': 'playlist.update',
                'playlist_id': playlist_id,
                'data': data,
            }
        )
        return JsonResponse({'message': 'Tracks reordered successfully'})

    except Playlist.DoesNotExist:
        return JsonResponse({'error': 'Playlist not found'}, status=404)
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=400)
