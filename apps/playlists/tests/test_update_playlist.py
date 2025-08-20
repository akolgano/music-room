import pytest
from django.urls import reverse
from rest_framework.test import APIClient
from apps.users.tests.conftest import authenticated_user
from apps.playlists.models import Playlist


@pytest.mark.django_db
def test_get_update_playlist_success(authenticated_user):
    """
        # Update playlist
        # Ensure get response {'message': 'Playlist updated successfully.'}
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
        "name": "Fav123",
        "description": "Fav123",
        "public": False
    }

    url = reverse("playlists:update_playlist", args=[playlist.id])

    response = client.patch(url, payload, format="json")
    assert response.status_code == 200
    assert response.json() == {'message': 'Playlist updated successfully.'}


@pytest.mark.django_db
def test_get_update_playlist_not_found(authenticated_user):
    """
        # Update invalid playlist
        # Ensure get response error {'detail': 'No Playlist matches the given query.'}
    """
    user, token = authenticated_user
    client = APIClient()
    client.credentials(HTTP_AUTHORIZATION=f"Token {token}")
    
    payload = {
        "name": "Fav123",
        "description": "Fav123",
        "public": False
    }

    url = reverse("playlists:update_playlist", args=[9999])

    response = client.patch(url, payload, format="json")
    assert response.status_code == 404
    assert response.json() == {'detail': 'No Playlist matches the given query.'}
