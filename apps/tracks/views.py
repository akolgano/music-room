from .models import Track
import requests
from django.http import JsonResponse
from apps.deezer.deezer_client import DeezerClient
from django.views.decorators.csrf import csrf_exempt


def get_deezer_tracks(query):
    """
    Fetch tracks from Deezer API based on a search query.
    """
    url = f"http://127.0.0.1:8000/deezer/search/?q={query}"
    response = requests.get(url)

    if response.status_code == 200:
        tracks = response.json().get('data', [])
        return tracks
    else:
        return None


def search_tracks(request):
    query = request.GET.get('query', '')
    tracks = []

    if query:
        tracks_data = get_deezer_tracks(query)

        if tracks_data:
            for track_data in tracks_data:
                Track.objects.update_or_create(
                    deezer_track_id=track_data['id'],
                    defaults={
                        'name': track_data['title'],
                        'artist': track_data['artist']['name'],
                        'album': track_data['album']['title'],
                        'url': track_data['link'],
                    }
                )

            tracks = Track.objects.filter(name__icontains=query)
        else:
            tracks = []

    return JsonResponse({'tracks': list(tracks.values())})


@csrf_exempt
def add_track_from_deezer(request, track_id):

    client = DeezerClient()
    track_data = client.get_track(track_id)
    if not track_data:
        return JsonResponse({"error": "Track not found on Deezer."}, status=404)

    track, created = Track.objects.get_or_create(
        name=track_data['title'],
        artist=track_data['artist']['name'],
        album=track_data['album']['title'],
        deezer_track_id=track_data['id'],
        url=track_data['link']
    )

    if created:
        return JsonResponse({"message": "Track added successfully."}, status=201)
    else:
        return JsonResponse({"message": "Track already exists."}, status=200)
