import pytest
from django.urls import reverse
from rest_framework.test import APIClient
from apps.users.tests.conftest import authenticated_user
from apps.playlists.models import Playlist, Track, PlaylistTrack
from django.contrib.auth import get_user_model
from uuid import UUID


User = get_user_model()


@pytest.mark.django_db
def test_invite_user_success(authenticated_user):
    """
        # Invite user to playlist
        # Ensure get response {'message': 'User invited to the playlist'}
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

    friend = User.objects.create_user(
        username="friend123",
        email="friend123@example.com",
        password="somePassword123"
    )

    payload = {
        "user_id": friend.id
    }

    url = reverse("playlists:invite_user", args=[playlist.id])

    response = client.post(url, payload, format="json")
    assert response.status_code == 201
    assert response.json() == {'message': 'User invited to the playlist'}


@pytest.mark.django_db
def test_invite_user_not_found_user(authenticated_user):
    """
        # Invite invalid user to playlist
        # Ensure get response error {'error': 'CustomUser matching query does not exist.'}
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
        "user_id": 0
    }

    url = reverse("playlists:invite_user", args=[playlist.id])

    response = client.post(url, payload, format="json")
    assert response.status_code == 400
    assert response.json() == {'error': 'CustomUser matching query does not exist.'}