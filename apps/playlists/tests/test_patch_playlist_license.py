import pytest
from django.urls import reverse
from rest_framework.test import APIClient
from apps.users.tests.conftest import authenticated_user
from apps.playlists.models import Playlist, Track, PlaylistTrack


@pytest.mark.django_db
def test_patch_playlist_license_success(authenticated_user):
    """
        # Update playlist license
        # Ensure get reponse matching the license type in payload
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
        "license_type": "invite_only"
    }

    url = reverse("playlists:patch_playlist_license", args=[playlist.id])

    response = client.patch(url, payload, format="json")
    assert response.status_code == 200
    data = response.json()
    assert data["license_type"] == "invite_only"


@pytest.mark.django_db
def test_patch_playlist_license_wrong_licence(authenticated_user):
    """
        # Update with invalid license type
        # Ensure get reponse error {'license_type': ['"some_licence" is not a valid choice.']}
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
        "license_type": "some_licence"
    }

    url = reverse("playlists:patch_playlist_license", args=[playlist.id])

    response = client.patch(url, payload, format="json")
    assert response.status_code == 400
    assert response.json() == {'license_type': ['"some_licence" is not a valid choice.']}


@pytest.mark.django_db
def test_patch_playlist_license_not_found(authenticated_user):
    """
        # Update with invalid playlist
        # Ensure get reponse error {'detail': 'Playlist not found'}
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
        "license_type": "invite_only"
    }

    url = reverse("playlists:patch_playlist_license", args=[9999])

    response = client.patch(url, payload, format="json")
    assert response.status_code == 404
    assert response.json() == {'detail': 'Playlist not found'}
