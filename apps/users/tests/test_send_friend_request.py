import pytest
from rest_framework.test import APIClient
from rest_framework.authtoken.models import Token
from django.urls import reverse
from django.contrib.auth import get_user_model
from apps.users.tests.conftest import authenticated_user
from apps.users.models import Friendship


User = get_user_model()


@pytest.mark.django_db
def test_send_friend_request_success(authenticated_user):
    """
        # Success sent friend request
        # Ensure response contains - 'Friend request sent to friend123.'
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


@pytest.mark.django_db
def test_send_friend_request_cannot_add_self(authenticated_user):
    """
        # Send friend request using own id
        # Ensure response error {'message': 'You cannot add yourself as a friend.'}
    """
    user, token = authenticated_user
    client = APIClient()
    client.credentials(HTTP_AUTHORIZATION=f"Token {token}")

    url = reverse("users:send_friend_request", args=[user.id])

    response = client.post(url)
    assert response.status_code == 400
    assert response.json() == {'message': 'You cannot add yourself as a friend.'}


@pytest.mark.django_db
def test_send_friend_request_already_pending(authenticated_user):
    """
        # Resend same friend id request
        # Ensure response error {'message': 'You already have a pending friend request.'}
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

    #send again same friend id
    url = reverse("users:send_friend_request", args=[friend.id])
    response = client.post(url)
    assert response.status_code == 400
    assert response.json() == {'message': 'You already have a pending friend request.'}


@pytest.mark.django_db
def test_send_friend_request_already_friend(authenticated_user):
    """
        # Send a user id that is already a friend
        # Ensure response error {'message': 'You are already friends.'}
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
        from_user=user,
        to_user=friend,
        status="accepted"
    )

    url = reverse("users:send_friend_request", args=[friend.id])
    response = client.post(url)
    assert response.status_code == 400
    assert response.json() == {'message': 'You are already friends.'}
