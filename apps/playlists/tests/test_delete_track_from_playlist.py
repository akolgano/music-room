import pytest
from django.urls import reverse
from rest_framework.test import APIClient
from apps.users.tests.conftest import authenticated_user
from apps.playlists.models import Playlist, Track, PlaylistTrack


@pytest.mark.django_db
def test_delete_track_in_playlist_success(authenticated_user):
    """
        # Delete a track in a playlist
        # Ensure get response {'message': 'Track deleted successfully'}
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

    payload = {
        "track_id": track1.id
    }

    url = reverse("playlists:remove_items", args=[playlist.id])

    response = client.post(url, payload, format="json")
    assert response.status_code == 200
    assert response.json() == {'message': 'Track deleted successfully'}


@pytest.mark.django_db
def test_delete_track_in_playlist_track_not_found(authenticated_user):
    """
        # Delete a invalid track in a playlist
        # Ensure get response {'error': 'Track not found in playlist'}
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

    payload = {
        "track_id": 9999
    }

    url = reverse("playlists:remove_items", args=[playlist.id])

    response = client.post(url, payload, format="json")
    assert response.status_code == 404
    assert response.json() == {'error': 'Track not found in playlist'}