import pytest
from django.urls import reverse
from rest_framework.test import APIClient
from unittest.mock import patch
from conftest import MockResponse
from apps.users.tests.conftest import authenticated_user
from apps.remote_auth.models import SocialNetwork
from django.contrib.auth import get_user_model
from uuid import UUID

User = get_user_model()

@patch('google.oauth2.id_token.verify_oauth2_token')
def test_google_link_invalid_token(mock_verify, authenticated_user):
    """
        # Mock id_token.verify_oauth2_token with invalid idToken
        # Ensure get response error {"error": "Invalid idToken"}
    """
    mock_verify.side_effect = ValueError("Invalid token")

    user, token = authenticated_user
    client = APIClient()
    client.credentials(HTTP_AUTHORIZATION=f"Token {token}")
    url = reverse('auth:google_link')

    payload = {
        "idToken": "invalid_token"
    }

    response = client.post(url, payload, format="json")
    assert response.status_code == 400
    assert response.json() == {"error": "Invalid idToken"}


def test_google_link_empty(authenticated_user):
    """
        # Empty payload
        # Ensure get response error {'error': 'Invalid social username'}
    """
    user, token = authenticated_user
    client = APIClient()
    client.credentials(HTTP_AUTHORIZATION=f"Token {token}")
    url = reverse('auth:google_link')

    payload = {}

    response = client.post(url, payload, format="json")
    assert response.status_code == 400
    assert response.json() == {'error': 'Invalid social username'}


def test_google_link_missing_social_id(authenticated_user):
    """
        # No id_token, missing socialId in payload
        # Ensure get response error {'error': 'Invalid social id'}
    """
    user, token = authenticated_user
    client = APIClient()
    client.credentials(HTTP_AUTHORIZATION=f"Token {token}")
    url = reverse('auth:google_link')

    payload = {
        "socialName": "my_name",
        "socialEmail": "user123@example.com"
    }

    response = client.post(url, payload, format="json")
    assert response.status_code == 400
    assert response.json() == {'error': 'Invalid social id'}


def test_google_link_missing_social_name(authenticated_user):
    """
        # No id_token, missing socialName in payload
        # Ensure get response error {'error': 'Invalid social username'}
    """
    user, token = authenticated_user
    client = APIClient()
    client.credentials(HTTP_AUTHORIZATION=f"Token {token}")
    url = reverse('auth:google_link')

    payload = {
        "socialId": "111111",
        "socialEmail": "user123@example.com"
    }

    response = client.post(url, payload, format="json")
    assert response.status_code == 400
    assert response.json() == {'error': 'Invalid social username'}


def test_google_link_missing_social_email(authenticated_user):
    """
        # No id_token, missing socialEmail in payload
        # Ensure get response error {'error': 'Invalid social email'}
    """
    user, token = authenticated_user
    client = APIClient()
    client.credentials(HTTP_AUTHORIZATION=f"Token {token}")
    url = reverse('auth:google_link')

    payload = {
        "socialId": "111111",
        "socialName": "my_name"
    }

    response = client.post(url, payload, format="json")
    assert response.status_code == 400
    assert response.json() == {'error': 'Invalid social email'}


@pytest.mark.django_db
def test_google_link_email_used_by_another_user(authenticated_user):
    """
        # Social email already in use
        # Ensure get response error {"error": "Email use by other user"}
    """
    another_user = User.objects.create_user(
        username="user248",
        email="user248@example.com",
        password="somePassword248"
    )

    user, token = authenticated_user
    client = APIClient()
    client.credentials(HTTP_AUTHORIZATION=f"Token {token}")
    url = reverse('auth:google_link')

    payload = {
        "socialId": "111111",
        "socialName": "my_name",
        "socialEmail": "user248@example.com"
    }

    response = client.post(url, payload, format="json")
    assert response.status_code == 400
    assert response.json() == {"error": "Email use by other user"}


@pytest.mark.django_db
def test_google_link_already_linked(authenticated_user):
    """
        # Social network already linked
        # Ensure get response error {"error": "Social network already linked"}
    """
    user, token = authenticated_user
    client = APIClient()
    client.credentials(HTTP_AUTHORIZATION=f"Token {token}")
    url = reverse('auth:google_link')

    SocialNetwork.objects.create(
        user=user,
        type="google",
        email="user123@example.com",
        name="my_name",
        social_id="111111"
    )

    payload = {
        "socialId": "111111",
        "socialName": "my_name",
        "socialEmail": "user123@example.com"
    }

    response = client.post(url, payload, format="json")
    assert response.status_code == 400
    assert response.json() == {"error": "Social network already linked"}


@pytest.mark.django_db
def test_google_link_success(authenticated_user):
    """
        # Valid payload
        # Ensure get response {'id': 5}
    """    
    user, token = authenticated_user
    client = APIClient()
    client.credentials(HTTP_AUTHORIZATION=f"Token {token}")
    url = reverse('auth:google_link')
    
    payload = {
        "socialId": "111111",
        "socialName": "my_name",
        "socialEmail": "user123@example.com"
    }

    response = client.post(url, payload, format="json")

    assert response.status_code == 200
    data = response.json()
    assert UUID(data["id"]) == user.id
    assert SocialNetwork.objects.filter(user=user, social_id="111111").exists()
