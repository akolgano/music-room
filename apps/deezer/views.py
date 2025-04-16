from django.http import JsonResponse
from .deezer_client import DeezerClient
from rest_framework.decorators import api_view
from rest_framework import status


@api_view(['GET'])
def get_deezer_track(request, track_id):
    client = DeezerClient()
    track_info = client.get_track(track_id)

    if track_info:
        return JsonResponse(track_info)
    else:
        return JsonResponse({'error': 'Track not found'}, status=404)


@api_view(['GET'])
def search_deezer_tracks(request):
    query = request.GET.get('q')
    if not query:
        return JsonResponse({"error": "Query parameter 'q' is required."}, status=status.HTTP_400_BAD_REQUEST)

    client = DeezerClient()
    results = client.search_tracks(query)

    if results is None:
        return JsonResponse({"error": "Failed to fetch data from Deezer."}, status=status.HTTP_502_BAD_GATEWAY)

    return JsonResponse(results)
