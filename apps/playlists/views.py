import json
from rest_framework.decorators import api_view, authentication_classes, permission_classes
from django.http import JsonResponse
from .models import Playlist, Track
from apps.tracks.models import Track
from django.shortcuts import get_object_or_404
from rest_framework.authentication import TokenAuthentication
from rest_framework.permissions import IsAuthenticated
from rest_framework import status
from apps.playlists.models import Playlist, PlaylistTrack
from django.db import models
from django.db import transaction
from channels.layers import get_channel_layer
from asgiref.sync import async_to_sync
from django.forms.models import model_to_dict
from .decorators import check_access_to_playlist, check_license
from .serializers import PlaylistLicenseSerializer
from apps.deezer.deezer_client import DeezerClient
from .serializers import PlaylistLicenseSerializer, VoteSerializer
from django.contrib.auth import get_user_model
from django.db.models import Q
from drf_spectacular.utils import extend_schema
from .docs import *


User = get_user_model()

@create_new_playlist_schema
@api_view(['POST'])
@authentication_classes([TokenAuthentication])
@permission_classes([IsAuthenticated])
def create_new_playlist(request):
    user = request.user
    name = request.data.get('name')
    description = request.data.get('description', '')
    public = request.data.get('public', True)
    license_type = request.data.get('license_type', 'open')
    event = request.data.get('event', False)
    if not name:
        return JsonResponse({"error": "Playlist name is required."}, status=400)
    playlist = Playlist.objects.create(
        name=name,
        description=description,
        public=public,
        license_type=license_type,
        creator=user,
        event = event
    )
    #playlist.users_saved.add(user)
    user.saved_playlists.add(playlist)

    return JsonResponse({
        "message": "Empty playlist is created.",
        "playlist_id": playlist.id
    }, status=201)


@update_playlist_schema
@api_view(['PATCH'])
@authentication_classes([TokenAuthentication])
@permission_classes([IsAuthenticated])
def update_playlist(request, playlist_id):
    user = request.user

    playlist = get_object_or_404(Playlist, id=playlist_id)

    if playlist.creator != user and playlist.public is False:
        return JsonResponse({"error": "You do not have permission to edit this playlist."}, status=403)


    name = request.data.get('name')
    description = request.data.get('description')
    public = request.data.get('public')
    license_type = request.data.get('license_type')
    event = request.data.get('event')

    if name is not None:
        playlist.name = name
    if description is not None:
        playlist.description = description
    if public is not None:
        playlist.public = public
    if license_type is not None:
        playlist.license_type = license_type
    if event is not None:
        playlist.event = event

    playlist.save()

    return JsonResponse({"message": "Playlist updated successfully."}, status=200)


@delete_playlist_schema
@api_view(['POST'])
@authentication_classes([TokenAuthentication])
@permission_classes([IsAuthenticated])
def delete_playlist(request, playlist_id):
    user = request.user

    playlist = get_object_or_404(Playlist, id=playlist_id)

    if playlist.creator != user and playlist.public is False:
        return JsonResponse({"error": "You do not have permission to delete this playlist."}, status=403)

    playlist.delete()

    return JsonResponse({"message": "Playlist deleted successfully."}, status=200)


@get_user_saved_playlists_schema
@api_view(['GET'])
@authentication_classes([TokenAuthentication])
@permission_classes([IsAuthenticated])
def get_user_saved_playlists(request):
    user = request.user

    
    playlists = Playlist.objects.filter(Q(users_saved=user) | Q(creator=user),
    event=False)

    playlist_data = []
    for playlist in playlists:
        tracks = playlist.tracks.all()
        track_list = [{'name': pt.track.name, 'artist': pt.track.artist} for pt in tracks]

        playlist_data.append({
            'id': playlist.id,
            'name': playlist.name,
            'description': playlist.description,
            'public': playlist.public,
            'creator': playlist.creator.username,
            #'license_type': playlist.license_type,
            'tracks': track_list,
        })

    return JsonResponse({'playlists': playlist_data})


@get_all_shared_playlists_schema
@api_view(['GET'])
@authentication_classes([TokenAuthentication])
@permission_classes([IsAuthenticated])
def get_all_shared_playlists(request):

    playlists = Playlist.objects.filter(public=True, event=False)

    playlist_data = []
    for playlist in playlists:
        tracks = playlist.tracks.all()
        track_list = [{'name': pt.track.name, 'artist': pt.track.artist} for pt in tracks]

        playlist_data.append({
            'id': playlist.id,
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


@get_playlist_info_schema
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

        shared_users = [{'id': user.id, 'username': user.username} for user in playlist.users_saved.all()]
        
        playlist_data.append({
            'id': playlist.id,
            'playlist_name': playlist.name,
            'description': playlist.description,
            'public': playlist.public,
            'creator': playlist.creator.username,
            'license_type': playlist.license_type,
            'tracks': track_list,
            'shared_with': shared_users,
            'event': playlist.event,
        })

        return JsonResponse({'playlist': playlist_data})
    except Playlist.DoesNotExist:
        return JsonResponse({"error": "Playlist not found."}, status=404)


@playlist_tracks_schema
@api_view(['GET'])
@authentication_classes([TokenAuthentication])
@permission_classes([IsAuthenticated])
def playlist_tracks(request, playlist_id):
    playlist = get_object_or_404(Playlist, id=playlist_id)
    tracks = PlaylistTrack.objects.filter(playlist=playlist).select_related('track')

    data = [{
        'track_id': pt.track.id,
        'playlist_track_id': pt.id,
        'deezer_track_id': pt.track.deezer_track_id,
        'name': pt.track.name,
        'position': pt.position,
        'points': pt.points,
    } for pt in tracks]

    return JsonResponse({'playlist': playlist.name, 'tracks': data})


@add_track_schema
@api_view(['POST'])
@authentication_classes([TokenAuthentication])
@permission_classes([IsAuthenticated])
@check_access_to_playlist
def add_track(request, playlist_id):
    if request.method != 'POST':
        return JsonResponse({'error': 'Invalid method'}, status=405)
    try:
        print('add_track starts')
        playlist = get_object_or_404(Playlist, id=playlist_id)
        data = request.data

        track_id = data.get("track_id")
        track = Track.objects.filter(id=track_id).first() or Track.objects.filter(deezer_track_id=track_id).first()
        if not track:
            from apps.deezer.deezer_client import DeezerClient
            client = DeezerClient()
            track_data = client.get_track(track_id)
            if not track_data:
                return JsonResponse({'error': 'Track not found on Deezer'}, status=404)
            track, _ = Track.objects.get_or_create(
                deezer_track_id=track_data['id'],
                defaults={
                    'name': track_data['title'],
                    'artist': track_data['artist']['name'],
                    'album': track_data['album']['title'],
                    'url': track_data['link']
                }
            )
        if PlaylistTrack.objects.filter(playlist=playlist, track=track).exists():
            return JsonResponse({'error': 'Track already in playlist'}, status=400)

        max_pos = PlaylistTrack.objects.filter(playlist=playlist).aggregate(models.Max('position'))['position__max'] or 0
        PlaylistTrack.objects.create(playlist=playlist, track=track, position=max_pos + 1)
        tracks = list(PlaylistTrack.objects.filter(playlist=playlist).order_by('position'))
        # Broadcast
        data = [{"id": t.id, "track": model_to_dict(t.track),"position": t.position} for t in tracks] 
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
        return JsonResponse({'status': 'track added', 'track_id': track.id}, status=201)
    except Playlist.DoesNotExist:
        return JsonResponse({'error': 'Playlist not found'}, status=404)
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=400)


@move_track_in_playlist_schema
@api_view(['POST'])
@authentication_classes([TokenAuthentication])
@permission_classes([IsAuthenticated])
@check_access_to_playlist
def move_track_in_playlist(request, playlist_id):
    if request.method != 'POST':
        return JsonResponse({'error': 'Invalid method'}, status=405)

    try:
        print('move_track_in_playlist starts')
        data = json.loads(request.body)
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
        # Broadcast
        data = [{"id": t.id, "track": model_to_dict(t.track),"position": t.position} for t in tracks]   
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


@delete_track_from_playlist_schema
@api_view(['POST'])
@authentication_classes([TokenAuthentication])
@permission_classes([IsAuthenticated])
@check_access_to_playlist
def delete_track_from_playlist(request, playlist_id):
    if request.method != 'POST':
        return JsonResponse({'error': 'Invalid method'}, status=405)

    try:
        print('delete_track_from_playlist starts')
        data = json.loads(request.body)

        track_id = data['track_id']
        playlist = Playlist.objects.get(id=playlist_id)
        track_to_delete = PlaylistTrack.objects.get(playlist=playlist, id=track_id)
        print(track_to_delete.id)
        with transaction.atomic():
            track_to_delete.delete()

            # Reorder
            remaining_tracks = list(PlaylistTrack.objects.filter(playlist=playlist).order_by('position'))

            TEMP_OFFSET = 1000
            for i, pt in enumerate(remaining_tracks):
                pt.position = i + TEMP_OFFSET
            PlaylistTrack.objects.bulk_update(remaining_tracks, ['position'])

            for i, pt in enumerate(remaining_tracks):
                pt.position = i
            PlaylistTrack.objects.bulk_update(remaining_tracks, ['position'])

        # Broadcast
        tracks = list(PlaylistTrack.objects.filter(playlist=playlist).order_by('position'))
        data = [{"id": t.id, "track": model_to_dict(t.track),"position": t.position} for t in tracks] 
        channel_layer = get_channel_layer()
        async_to_sync(channel_layer.group_send)(
            f'playlist_{playlist_id}',
            {
                'type': 'playlist.update',
                'playlist_id': playlist_id,
                'data': data,
            }
        )

        return JsonResponse({'message': 'Track deleted successfully'})

    except Playlist.DoesNotExist:
        return JsonResponse({'error': 'Playlist not found'}, status=404)
    except PlaylistTrack.DoesNotExist:
        return JsonResponse({'error': 'Track not found in playlist'}, status=404)
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=400)


@change_visibility_schema
@api_view(['POST'])
@authentication_classes([TokenAuthentication])
@permission_classes([IsAuthenticated])
def change_visibility(request, playlist_id):
    try:
        public = request.data.get('public', True)
        playlist = Playlist.objects.get(id=playlist_id)
        playlist.public = public
        playlist.save()
        print(playlist.users_saved.all())
        return JsonResponse({'message': 'Playlist visibility changed successfully'})
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=400)    


@invite_user_schema
@api_view(['POST'])
@authentication_classes([TokenAuthentication])
@permission_classes([IsAuthenticated])
@check_access_to_playlist
def invite_user(request, playlist_id):
    try:
        
        user_id=request.data.get('user_id')
        playlist = Playlist.objects.get(id=playlist_id)
        print(playlist.users_saved.all())
        user_to_invite = User.objects.get(id=user_id)
        if user_to_invite in playlist.users_saved.all():
            return JsonResponse({'message': 'User already invited'}, status=200)
        playlist.users_saved.add(user_to_invite)
        print(playlist.users_saved.all())
        data = [{"user_id": user_id, "text": "User invited to the playlist"}]
        channel_layer = get_channel_layer()

        # Broadcast
        async_to_sync(channel_layer.group_send)(
            f'playlist_{playlist_id}',
            {
                'type': 'playlist.update',
                'playlist_id': playlist_id,
                'data': data,
            }
        )
        return JsonResponse({'message': 'User invited to the playlist'}, status=201)
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=400)


@patch_playlist_license_schema
@api_view(['GET', 'PATCH'])
@authentication_classes([TokenAuthentication])
@permission_classes([IsAuthenticated])
def patch_playlist_license(request, playlist_id):
    try:
        playlist = Playlist.objects.get(id=playlist_id)
    except Playlist.DoesNotExist:
        return JsonResponse({'detail': 'Playlist not found'}, status=404)

    if playlist.creator != request.user:
        return JsonResponse({'detail': 'You do not have permission to edit this playlist license.'}, status=403)

    if request.method == 'GET':
        serializer = PlaylistLicenseSerializer(playlist)
        return JsonResponse(serializer.data, status=200)

    serializer = PlaylistLicenseSerializer(playlist, data=request.data, partial=True)
    if serializer.is_valid():
        serializer.save()
        return JsonResponse(serializer.data, status=200)
    return JsonResponse(serializer.errors, status=400)


@vote_for_track_schema
@api_view(['POST'])
@authentication_classes([TokenAuthentication])
@permission_classes([IsAuthenticated])
@check_license
def vote_for_track(request, playlist_id):
    try:
        playlist = Playlist.objects.get(id=playlist_id)
    except Playlist.DoesNotExist:
        return JsonResponse({'detail': 'Playlist not found'}, status=404)
    serializer = VoteSerializer(data=request.data)
    if serializer.is_valid():
        range_start = serializer.validated_data["range_start"]
        tracks = list(PlaylistTrack.objects.filter(playlist=playlist).order_by('position'))
        if range_start >= len(tracks) or range_start < 0:
            return JsonResponse({'error': 'Invalid track index'}, status=400)
        print(tracks[range_start])
        pt = tracks[range_start]
        user = request.user
        print("Users who already voted:", list(playlist.users_already_voted.all()))
        if not playlist.users_already_voted.filter(id=user.id).exists():
            with transaction.atomic():
                pt.points += 1
                pt.save()
                playlist.users_already_voted.add(request.user)
                playlist.save()
        else:
            return JsonResponse({'error': 'You have already voted for this playlist'}, status=403)
        data = [{"id": t.id, "track": model_to_dict(t.track),"position": t.position, "points": t.points} for t in tracks]
        channel_layer = get_channel_layer()
        async_to_sync(channel_layer.group_send)(
            f'playlist_{playlist_id}',
            {
                'type': 'playlist.update',
                'playlist_id': playlist_id,
                'data': data,
            }
        )
        playlist_data = []
        tracks = playlist.tracks.all()
        track_list = [{'name': pt.track.name, 'artist': pt.track.artist, 'points': pt.points} for pt in tracks]

        playlist_data.append({
            'id': playlist.id,
            'playlist_name': playlist.name,
            'description': playlist.description,
            'public': playlist.public,
            'creator': playlist.creator.username,
            'tracks': track_list,
        })

        return JsonResponse({'playlist': playlist_data})
    return JsonResponse(serializer.errors, status=400)


@get_user_saved_events_schema
@api_view(['GET'])
@authentication_classes([TokenAuthentication])
@permission_classes([IsAuthenticated])
def get_user_saved_events(request):
    user = request.user

    playlists = Playlist.objects.filter(Q(users_saved=user) | Q(creator=user), event=True)

    playlist_data = []
    for playlist in playlists:
        tracks = playlist.tracks.all()
        track_list = [{'name': pt.track.name, 'artist': pt.track.artist} for pt in tracks]

        playlist_data.append({
            'id': playlist.id,
            'name': playlist.name,
            'description': playlist.description,
            'public': playlist.public,
            'creator': playlist.creator.username,
            'license_type': playlist.license_type,
            'tracks': track_list,
        })

    return JsonResponse({'events': playlist_data})


@get_all_shared_events_schema
@api_view(['GET'])
@authentication_classes([TokenAuthentication])
@permission_classes([IsAuthenticated])
def get_all_shared_events(request):

    playlists = Playlist.objects.filter(public=True, event=True)

    playlist_data = []
    for playlist in playlists:
        tracks = playlist.tracks.all()
        track_list = [{'name': pt.track.name, 'artist': pt.track.artist} for pt in tracks]

        playlist_data.append({
            'id': playlist.id,
            'name': playlist.name,
            'description': playlist.description,
            'public': playlist.public,
            'creator': playlist.creator.username,  # Show the creator of the playlist
            'tracks': track_list,
            'license_type': playlist.license_type,
        })

    return JsonResponse({'events': playlist_data})