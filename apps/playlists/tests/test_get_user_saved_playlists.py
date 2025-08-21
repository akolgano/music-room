import pytest
from django.urls import reverse
from rest_framework.test import APIClient
from apps.users.tests.conftest import authenticated_user
from apps.playlists.models import Playlist, Track, PlaylistTrack


@pytest.mark.django_db
def test_get_user_saved_playlist_success(authenticated_user):
    """
        # Get user saved playlists
        # Ensure get matching playlist as created
    """
    user, token = authenticated_user
    client = APIClient()
    client.credentials(HTTP_AUTHORIZATION=f"Token {token}")

    playlist = Playlist.objects.create(
        name="Fav999",
        description="Fav999",
        public=True,
        license_type="open",
        creator=user,
        event=False
    )

    track1 = Track.objects.create(
        name="Song A",
        artist="Artist A",
        deezer_track_id="1000"
    )

    PlaylistTrack.objects.create(
        playlist=playlist,
        track=track1,
        position=0,
        points=0
    )

    url = reverse("playlists:saved_playlists")

    response = client.get(url, format="json")
    assert response.status_code == 200
    data = response.json()
    data = data["playlists"]
    assert data[0]["id"] == playlist.id
