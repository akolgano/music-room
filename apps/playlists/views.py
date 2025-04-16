from rest_framework.decorators import api_view
from django.http import JsonResponse
from .models import Playlist
from apps.tracks.models import Track
from django.shortcuts import get_object_or_404


@api_view(['GET'])
def get_user_saved_playlists(request):
    user = request.user

    playlists = Playlist.objects.filter(users_saved=user)

    playlist_data = []
    for playlist in playlists:
        tracks = playlist.tracks.all()
        track_list = [{'name': track.name, 'artist': track.artist} for track in tracks]

        playlist_data.append({
            'name': playlist.name,
            'description': playlist.description,
            'public': playlist.public,
            'creator': playlist.creator.username,
            'tracks': track_list,
        })

    return JsonResponse({'playlists': playlist_data})


@api_view(['GET'])
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
def add_track_to_playlist(request, playlist_id, track_id):
    try:
        playlist = get_object_or_404(Playlist, id=playlist_id)
        track = get_object_or_404(Track, id=track_id)
        playlist.tracks.add(track)

        return JsonResponse({
            "message": "Track added to playlist successfully.",
            "playlist_id": playlist.id,
            "track_id": track.id
        }, status=200)

    except Playlist.DoesNotExist:
        return JsonResponse({"error": "Playlist not found."}, status=404)
    except Track.DoesNotExist:
        return JsonResponse({"error": "Track not found."}, status=404)
