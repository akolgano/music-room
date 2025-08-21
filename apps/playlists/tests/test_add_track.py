import pytest
from django.urls import reverse
from rest_framework.test import APIClient
from apps.users.tests.conftest import authenticated_user
from apps.playlists.models import Playlist, Track, PlaylistTrack


@pytest.mark.django_db
def test_add_track_success(authenticated_user):
    """
        # Add a track to playlist
        # Ensure get response matching track_id added
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

    payload = {
        "track_id": track1.id
    }

    url = reverse("playlists:add_track", args=[playlist.id])

    response = client.post(url, payload, format="json")
    assert response.status_code == 201
    data = response.json()
    assert data["track_id"] == track1.id


@pytest.mark.django_db
def test_add_track_already_exist(authenticated_user):
    """
        # Add a already exist track to playlist
        # Ensure get response error {'error': 'Track already in playlist'}
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

    payload = {
        "track_id": track1.id
    }

    url = reverse("playlists:add_track", args=[playlist.id])

    response = client.post(url, payload, format="json")
    assert response.status_code == 201
    data = response.json()
    assert data["track_id"] == track1.id

    #add again
    response = client.post(url, payload, format="json")
    assert response.status_code == 400
    assert response.json() == {'error': 'Track already in playlist'}
