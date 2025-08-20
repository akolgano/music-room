import pytest
from django.urls import reverse
from rest_framework.test import APIClient
from apps.users.tests.conftest import authenticated_user
from apps.playlists.models import Playlist, Track, PlaylistTrack


@pytest.mark.django_db
def test_move_track_in_playlist_success(authenticated_user):
    """
        # Move a track position in a playlist
        # Ensure get response {'message': 'Tracks reordered successfully'}
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
        position=0,
        points=0
    )
    PlaylistTrack.objects.create(
        playlist=playlist,
        track=track2,
        position=1,
        points=0
    )

    payload = {
        "range_start": 0,
        "insert_before": 2,
        "range_length": 1
    }

    url = reverse("playlists:move_track_in_playlist", args=[playlist.id])

    response = client.post(url, payload, format="json")
    assert response.status_code == 200
    assert response.json() == {'message': 'Tracks reordered successfully'}


@pytest.mark.django_db
def test_move_track_in_playlist_invalid_range(authenticated_user):
    """
        # Invalid range input
        # Ensure get response error {'error': 'Invalid range'}
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
        position=0,
        points=0
    )
    PlaylistTrack.objects.create(
        playlist=playlist,
        track=track2,
        position=1,
        points=0
    )

    payload = {
        "range_start": 100,
        "insert_before": 2,
        "range_length": 1
    }

    url = reverse("playlists:move_track_in_playlist", args=[playlist.id])

    response = client.post(url, payload, format="json")
    assert response.status_code == 400
    assert response.json() == {'error': 'Invalid range'}
