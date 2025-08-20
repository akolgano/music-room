import pytest
from django.urls import reverse
from rest_framework.test import APIClient
from apps.users.tests.conftest import authenticated_user
from apps.playlists.models import Playlist


@pytest.mark.django_db
def test_create_playlist_success(authenticated_user):
    """
        # Create a new empty playlist
        # Ensure get status 201
    """
    user, token = authenticated_user
    client = APIClient()
    client.credentials(HTTP_AUTHORIZATION=f"Token {token}")

    url = reverse("playlists:playlists")

    payload = {
        "name": "Fav999",
        "description": "Fav999",
        "public": True,
        "license_type": "open",
        "event": False
    }

    response = client.post(url, payload, format="json")
    assert response.status_code == 201
    data = response.json()
    playlist = Playlist.objects.get(id=data["playlist_id"])
    assert playlist.name == "Fav999"
    assert playlist.creator == user


@pytest.mark.django_db
def test_create_playlist_missing_name(authenticated_user):
    """
        # Missing name in payload
        # Ensure get error response {'error': 'Playlist name is required.'}
    """
    user, token = authenticated_user
    client = APIClient()
    client.credentials(HTTP_AUTHORIZATION=f"Token {token}")

    url = reverse("playlists:playlists")

    payload = {
        "description": "No name provided",
        "public": True,
        "license_type": "open",
        "event": False
    }

    response = client.post(url, payload, format="json")
    assert response.status_code == 400, response.json()
    assert response.json() == {'error': 'Playlist name is required.'}
