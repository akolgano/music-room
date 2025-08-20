import pytest
from django.urls import reverse
from rest_framework.test import APIClient
from apps.users.tests.conftest import authenticated_user
from apps.playlists.models import Playlist, Track, PlaylistTrack


@pytest.mark.django_db
def test_get_playlist_with_tracks(authenticated_user):
    """
        # Get tracks in playlist
        # Ensure get response matching song tracks of the playlist
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
    track2 = Track.objects.create(
        name="Song B",
        artist="Artist B",
        deezer_track_id="1001"
    )

    PlaylistTrack.objects.create(
        playlist=playlist,
        track=track1,
        position=1,
        points=0
    )
    PlaylistTrack.objects.create(
        playlist=playlist,
        track=track2,
        position=2,
        points=0
    )

    url = reverse("playlists:playlist_tracks", args=[playlist.id])

    response = client.get(url)

    assert response.status_code == 200
    data = response.json()
    assert data["playlist"] == playlist.name
    assert len(data["tracks"]) == 2
    assert {t["name"] for t in data["tracks"]} == {"Song A", "Song B"}


@pytest.mark.django_db
def test_get_playlist_not_found(authenticated_user):
    """
        # Invalid playlist
        # Ensure get response error {'detail': 'No Playlist matches the given query.'}
    """
    user, token = authenticated_user
    client = APIClient()
    client.credentials(HTTP_AUTHORIZATION=f"Token {token}")

    url = reverse("playlists:playlist_tracks", args=[9999])

    response = client.get(url)

    assert response.status_code == 404
    assert response.json() == {'detail': 'No Playlist matches the given query.'}
