from functools import wraps
from rest_framework.response import Response
from apps.playlists.models import Playlist


def check_access_to_playlist(view_func):
    @wraps(view_func)
    def _wrapped_view(request, *args, **kwargs):
        user = request.user
        playlist_id = kwargs.get('playlist_id')
        print('check_access_to_playlist')
        print(playlist_id)
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
