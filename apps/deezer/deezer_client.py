import requests

DEEZER_API_URL = "https://api.deezer.com"

class DeezerClient:
    def __init__(self):
        pass

    def get_track(self, track_id):
        """
        Get a track by its ID from Deezer.
        """
        url = f"{DEEZER_API_URL}/track/{track_id}"
        response = requests.get(url)
        return response.json() if response.status_code == 200 else None

    def get_album(self, album_id):
        """
        Get an album by its ID from Deezer.
        """
        url = f"{DEEZER_API_URL}/album/{album_id}"
        response = requests.get(url)
        return response.json() if response.status_code == 200 else None

    def get_artist(self, artist_id):
        """
        Get an artist by their ID from Deezer.
        """
        url = f"{DEEZER_API_URL}/artist/{artist_id}"
        response = requests.get(url)
        return response.json() if response.status_code == 200 else None

    def search_tracks(self, query):
        """
        Search for tracks by name or keyword.
        """
        url = f"{DEEZER_API_URL}/search"
        params = {'q': query}
        response = requests.get(url, params=params)
        return response.json() if response.status_code == 200 else None
