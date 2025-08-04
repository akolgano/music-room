import pytest
from django.urls import reverse
from rest_framework.test import APIClient
from apps.users.tests.conftest import authenticated_user
from apps.profile.tests.conftest import user_init_profile
import uuid


def test_profile_view_own(authenticated_user):
    """
        # Authenticated user with default init profile values
        # Ensure response matches the default init profile values
    """
    user, token = authenticated_user
    client = APIClient()
    client.credentials(HTTP_AUTHORIZATION=f"Token {token}")

    user = user_init_profile(authenticated_user)
    url = reverse('profile:profile-detail', kwargs={'pk': user.id})

    response = client.get(url)
    assert response.status_code == 200
    data = response.json()

    assert data["avatar"] == "http://testserver/apps/profile/avatars/user123_xxx.png"
    assert data["name"] == "user123"
    assert data["location"] == "SUTD"
    assert data["bio"] == "Hello !"
    assert data["phone"] == "+6591234567"
    assert data["friend_info"] == "Hello Friend !"
    assert set(data["music_preferences"]) == {"rock", "jazz"}


def test_profile_view_not_found(authenticated_user):
    """
        # Invalid user uuid
        # Ensure response error {'detail': 'No Profile matches the given query.'}
    """
    user, token = authenticated_user
    client = APIClient()
    client.credentials(HTTP_AUTHORIZATION=f"Token {token}")

    test_uuid = uuid.uuid4()
    url = reverse('profile:profile-detail', kwargs={'pk': test_uuid})

    response = client.get(url)
    assert response.status_code == 404
    assert response.json() == {'detail': 'No Profile matches the given query.'}
