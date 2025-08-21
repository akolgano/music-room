import pytest
from django.urls import reverse
from rest_framework.test import APIClient
from apps.users.tests.conftest import authenticated_user
from apps.playlists.models import Playlist, Track, PlaylistTrack


@pytest.mark.django_db
def test_vote_for_track_success(authenticated_user):
    """
        # Vote a track in a playlist
        # Ensure get response - playlist track points increased by 1
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

    playlist_track = PlaylistTrack.objects.create(
        playlist=playlist,
        track=track1,
        position=0,
        points=0
    )

    payload = {
        "range_start": 0
    }

    url = reverse("playlists:vote_for_track", args=[playlist.id])

    response = client.post(url, payload, format="json")
    assert response.status_code == 200

    pt = PlaylistTrack.objects.filter(playlist=playlist).first()
    assert pt.points == 1


@pytest.mark.django_db
def test_vote_for_track_already_voted(authenticated_user):
    """
        # Vote a already voted track in a playlist
        # Ensure get response error {'error': 'You have already voted for this playlist'}
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

    playlist_track = PlaylistTrack.objects.create(
        playlist=playlist,
        track=track1,
        position=0,
        points=0
    )

    payload = {
        "range_start": 0
    }

    url = reverse("playlists:vote_for_track", args=[playlist.id])

    response = client.post(url, payload, format="json")
    assert response.status_code == 200

    # vote again
    response = client.post(url, payload, format="json")
    assert response.status_code == 403
    assert response.json() == {'error': 'You have already voted for this playlist'}


@pytest.mark.django_db
def test_vote_for_track_invalid_range(authenticated_user):
    """
        # Vote a invalid track in a playlist
        # Ensure get response error {'error': 'Invalid track index'}
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

    playlist_track = PlaylistTrack.objects.create(
        playlist=playlist,
        track=track1,
        position=0,
        points=0
    )

    payload = {
        "range_start": 100
    }

    url = reverse("playlists:vote_for_track", args=[playlist.id])

    response = client.post(url, payload, format="json")
    assert response.status_code == 400
    assert response.json() == {'error': 'Invalid track index'}
