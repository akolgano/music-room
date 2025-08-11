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
def test_remove_friend_success(authenticated_user):
    """
        # Remove a friend
        # Ensure response {'message': 'Friend removed successfully.'}
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

    url = reverse("users:remove_friend", args=[friend.id])
    response = client.post(url)
    assert response.status_code == 200
    assert response.json() == {'message': 'Friend removed successfully.'}


@pytest.mark.django_db
def test_remove_friend_no_friend(authenticated_user):
    """
        # Remove a non-existant friend
        # Ensure response error {'message': 'You are not friends with this user.'}
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

    url = reverse("users:remove_friend", args=[friend.id])
    response = client.post(url)
    assert response.status_code == 400
    assert response.json() == {'message': 'You are not friends with this user.'}
