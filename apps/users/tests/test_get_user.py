import pytest
from rest_framework.test import APIClient
from rest_framework.authtoken.models import Token
from django.urls import reverse
from unittest.mock import patch
from apps.remote_auth.models import SocialNetwork
from django.contrib.auth import get_user_model


User = get_user_model()

@pytest.mark.django_db
def test_get_user_no_social(authenticated_user):
    """
        # User without socialnetwork link
        # Ensure get response 200 with correct username as authenticated user
    """
    user, token = authenticated_user
    client = APIClient()
    client.credentials(HTTP_AUTHORIZATION=f"Token {token}")
    url = reverse("users:get_user")

    response = client.get(url)

    assert response.status_code == 200
    data = response.json()
    assert data["username"] == user.username
    assert data["email"] == user.email


@pytest.mark.django_db
def test_get_user_with_social(authenticated_user):
    """
        # User with socialnetwork link
        # Ensure get response 200 with correct username as authenticated user
    """
    user, token = authenticated_user
    client = APIClient()
    client.credentials(HTTP_AUTHORIZATION=f"Token {token}")
    url = reverse("users:get_user")

    SocialNetwork.objects.create(
        user=user,
        type="google",
        social_id="1111111111",
        email="googleuser123@example.com",
        name="google user123"
    )

    response = client.get(url)

    assert response.status_code == 200
    data = response.json()
    assert data["username"] == user.username
    assert data["email"] == user.email
    assert data["has_social_account"] is True
    assert data["social"]["type"] == "google"
    assert data["social"]["social_id"] == "1111111111"
    

@pytest.mark.django_db
def test_get_user_unauthenticated():
    """
        # Unauthenticated user
        # Ensure get response error 401
    """
    client = APIClient()
    url = reverse("users:get_user")

    response = client.get(url)

    assert response.status_code == 401