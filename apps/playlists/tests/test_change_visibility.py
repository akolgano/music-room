import pytest
from django.urls import reverse
from rest_framework.test import APIClient
from apps.users.tests.conftest import authenticated_user
from apps.playlists.models import Playlist, Track, PlaylistTrack


@pytest.mark.django_db
def test_change_visibility_success(authenticated_user):
    """
        # Change visibility of playlist
        # Ensure get response {'message': 'Playlist visibility changed successfully'}
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
        "public": False
    }

    url = reverse("playlists:change_visibility", args=[playlist.id])

    response = client.post(url, payload, format="json")
    assert response.status_code == 200
    assert response.json() == {'message': 'Playlist visibility changed successfully'}
