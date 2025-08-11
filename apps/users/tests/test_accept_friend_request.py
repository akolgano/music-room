import pytest
from rest_framework.test import APIClient
from rest_framework.authtoken.models import Token
from django.urls import reverse
from django.contrib.auth import get_user_model
from apps.users.tests.conftest import authenticated_user
from apps.users.models import Friendship


User = get_user_model()

@pytest.mark.django_db
def test_accept_friend_request_success(authenticated_user):
    """
        # Accept a pending friend request
        # Ensure response {'message': 'You are now friends with friend123!'}
    """
    user, token = authenticated_user
    client = APIClient()
    client.credentials(HTTP_AUTHORIZATION=f"Token {token}")
    
    friend = User.objects.create_user(
        username="friend123",
        email="friend123@example.com",
        password="somePassword123"
    )

    friendship = Friendship.objects.create(
        from_user=friend,
        to_user=user,
        status="pending"
    )

    url = reverse("users:accept_friend_request", args=[friendship.id])
    response = client.post(url)
    assert response.status_code == 200
    assert response.json() == {'message': 'You are now friends with friend123!'}


@pytest.mark.django_db
def test_accept_friend_request_not_found(authenticated_user):
    """
        # Accept a non exists friendship request
        # Ensure response error {'detail': 'No Friendship matches the given query.'}
    """
    user, token = authenticated_user
    client = APIClient()
    client.credentials(HTTP_AUTHORIZATION=f"Token {token}")

    url = reverse("users:accept_friend_request", args=[999])
    response = client.post(url)
    assert response.status_code == 404
    assert response.json() == {'detail': 'No Friendship matches the given query.'}
