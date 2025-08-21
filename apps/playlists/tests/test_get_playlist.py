import pytest
from django.urls import reverse
from rest_framework.test import APIClient
from apps.users.tests.conftest import authenticated_user
from apps.playlists.models import Playlist


@pytest.mark.django_db
def test_get_playlist_info_success(authenticated_user):
    """
        # Get playlist info
        # Ensure get response playlist id is same as created
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
    
    url = reverse("playlists:get_playlist", args=[playlist.id])

    response = client.get(url, format="json")
    assert response.status_code == 200
    data = response.json()
    data = data["playlist"][0]
    assert data["id"] == playlist.id


@pytest.mark.django_db
def test_get_playlist_info_not_found(authenticated_user):
    """
        # Get invalid playlist info
        # Ensure get response error {'detail': 'No Playlist matches the given query.'}
    """
    user, token = authenticated_user
    client = APIClient()
    client.credentials(HTTP_AUTHORIZATION=f"Token {token}")

    url = reverse("playlists:get_playlist", args=[9999])

    response = client.get(url, format="json")
    assert response.status_code == 404
    assert response.json() == {'detail': 'No Playlist matches the given query.'}
