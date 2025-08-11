import pytest
from rest_framework.test import APIClient
from rest_framework.authtoken.models import Token
from django.urls import reverse
from django.contrib.auth import get_user_model
from apps.users.tests.conftest import authenticated_user
from apps.users.models import Friendship
from uuid import UUID


User = get_user_model()


@pytest.mark.django_db
def test_get_friends_success(authenticated_user):
    """
        # List all 'accepted' friends
        # Ensure response matches friend details
    """
    user, token = authenticated_user
    client = APIClient()
    client.credentials(HTTP_AUTHORIZATION=f"Token {token}")

    friend = User.objects.create_user(
        username="friend123",
        email="friend123@example.com",
        password="somePassword123"
    )

    Friendship.objects.create(
        from_user=friend,
        to_user=user,
        status="accepted"
    )

    url = reverse("users:get_friends")
    response = client.get(url)
    assert response.status_code == 200
    result = response.json()

    result = result["friends"][0]
    assert UUID(result["friend_id"]) == friend.id
    assert result["friend_username"] == friend.username


@pytest.mark.django_db
def test_get_friends_no_friends(authenticated_user):
    """
        # List if no 'accepted' friends
        # Ensure response {'friends': []}
    """
    user, token = authenticated_user
    client = APIClient()
    client.credentials(HTTP_AUTHORIZATION=f"Token {token}")

    friend = User.objects.create_user(
        username="friend123",
        email="friend123@example.com",
        password="somePassword123"
    )

    Friendship.objects.create(
        from_user=friend,
        to_user=user,
        status="pending"
    )

    url = reverse("users:get_friends")
    response = client.get(url)
    assert response.status_code == 200
    assert response.json() == {'friends': []}
