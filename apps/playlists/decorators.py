from functools import wraps
from rest_framework.response import Response
from rest_framework import status
from apps.playlists.models import Playlist
from datetime import datetime, timedelta
from django.shortcuts import get_object_or_404
from geopy.distance import geodesic


def get_user_coordinates(request):
    try:
        lat = float(request.headers.get("X-User-Latitude"))
        lon = float(request.headers.get("X-User-Longitude"))
        return (lat, lon)
    except (TypeError, ValueError):
        return None

def check_access_to_playlist(view_func):
    @wraps(view_func)
    def _wrapped_view(request, *args, **kwargs):
        user = request.user
        playlist_id = kwargs.get('playlist_id')
        print('check_access_to_playlist')
        if not playlist_id:
            return Response({'error': 'Missing playlist id'}, status=400)

        try:
            playlist = Playlist.objects.get(id=playlist_id)
        except Playlist.DoesNotExist:
            return Response({'error': 'Playlist not found'}, status=404)
        print(playlist.public)
        if user not in playlist.users_saved.all() and not playlist.public:
            return Response({'error': 'Permission denied for this playlist'}, status=403)

        return view_func(request, *args, **kwargs)
    return _wrapped_view


def check_license(view_func):
    @wraps(view_func)
    def _wrapped_view(request, *args, **kwargs):
        user = request.user
        playlist_id = kwargs.get("playlist_id")
        playlist = get_object_or_404(Playlist, id=playlist_id)
        latlon = get_user_coordinates(request)
        print(latlon)
        print(playlist.license_type)

        if playlist.license_type == "open":
            return view_func(request, *args, **kwargs)

        elif playlist.license_type == "invite_only":
            if user.is_authenticated and user in playlist.invited_users.all():
                return view_func(request, *args, **kwargs)
            return Response(
                {"detail": "You are not invited to vote on this playlist."},
                status=status.HTTP_403_FORBIDDEN,
            )

        elif playlist.license_type == "location_time":
            now = datetime.now().time()
            print(now)
            #change later for Singapore time properly
            now = (datetime.utcnow() + timedelta(hours=8)).time()
            print(now)

            if not (playlist.vote_start_time and playlist.vote_end_time):
                return Response(
                    {"detail": "Voting time window not configured."},
                    status=status.HTTP_403_FORBIDDEN,
                )
            if not (playlist.vote_start_time <= now <= playlist.vote_end_time):
                return Response(
                    {"detail": "Voting is not allowed at this time."},
                    status=status.HTTP_403_FORBIDDEN,
                )

            latlon = get_user_coordinates(request)
            print(latlon)
            if not latlon:
                return Response(
                    {"detail": "User location is missing."},
                    status=status.HTTP_403_FORBIDDEN,
                )

            if not (playlist.latitude and playlist.longitude and playlist.allowed_radius_meters):
                return Response(
                    {"detail": "Playlist location settings not configured."},
                    status=status.HTTP_403_FORBIDDEN,
                )

            distance = geodesic(latlon, (playlist.latitude, playlist.longitude)).meters
            if distance > playlist.allowed_radius_meters:
                return Response(
                    {"detail": "You are not within the allowed voting area."},
                    status=status.HTTP_403_FORBIDDEN,
                )

            return view_func(request, *args, **kwargs)

        return Response(
            {"detail": "Voting not allowed under current license settings."},
            status=status.HTTP_403_FORBIDDEN,
        )

    return _wrapped_view