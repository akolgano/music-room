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
def test_get_sent_friend_request_success(authenticated_user):
    """
        # Current sent friend request list
        # Ensure response contains matching friend details
    """
    user, token = authenticated_user
    client = APIClient()
    client.credentials(HTTP_AUTHORIZATION=f"Token {token}")
    
    friend = User.objects.create_user(
        username="friend123",
        email="friend123@example.com",
        password="somePassword123"
    )

    url = reverse("users:send_friend_request", args=[friend.id])
    response = client.post(url)
    assert response.status_code == 201
    result = response.json()
    assert result["message"] == 'Friend request sent to friend123.'

    url = reverse("users:get_sent_friend_request")
    response = client.get(url)
    assert response.status_code == 200
    result = response.json()

    result = result["sent_invitations"][0]
    assert UUID(result["friend_id"]) == friend.id
    assert result["friend_username"] == friend.username
