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

@pytest.mark.django_db
@patch('requests.get')
def test_facebook_link_invalid_token(mock_get, authenticated_user):
    """
        # Mock request with invalid fbAccessToken
        # Ensure get response error {"error": "Invalid Facebook access token"}
    """
    user, token = authenticated_user
    client = APIClient()
    client.credentials(HTTP_AUTHORIZATION=f"Token {token}")
    
    mock_get.return_value = MockResponse({"data": {"is_valid": False}}, 200)

    url = reverse("auth:facebook_link")

    payload = {
        "fbAccessToken": "invalid_token"
    }

    response = client.post(url, payload, format="json")
    assert response.status_code == 400
    assert response.json() == {"error": "Invalid Facebook access token"}


@pytest.mark.django_db
@patch('requests.get')
def test_facebook_link_empty_token(mock_get, authenticated_user):
    """
        # Empty payload
        # Ensure get response error {'error': 'Access token not provided'}
    """
    user, token = authenticated_user
    client = APIClient()
    client.credentials(HTTP_AUTHORIZATION=f"Token {token}")
    url = reverse("auth:facebook_link")

    payload = {}

    response = client.post(url, payload, format="json")
    assert response.status_code == 400
    assert response.json() == {'error': 'Access token not provided'}


@pytest.mark.django_db
@patch('requests.get')
def test_facebook_link_missing_fb_email(mock_get, authenticated_user):
    """
        # Mock responses from fb with missing email return
        # Ensure get response error {"error": "Invalid login credentials"}
    """
    mock_get.side_effect = [
        MockResponse({"data": {"is_valid": True, "user_id": "123"}}, 200),
        MockResponse({"id": "123", "name": "my_name"}, 200)
    ]
    user, token = authenticated_user
    client = APIClient()
    client.credentials(HTTP_AUTHORIZATION=f"Token {token}")
    url = reverse("auth:facebook_link")

    payload = {
        "fbAccessToken": "1111111111"
    }

    response = client.post(url, payload, format='json')
    assert response.status_code == 400
    assert response.json() == {"error": "Invalid login credentials"}


@pytest.mark.django_db
@patch('requests.get')
def test_facebook_link_email_used_by_another_user(mock_get, authenticated_user):
    """
        # Social email already in use
        # Ensure get response error {"error": "Email use by other user"}
    """
    mock_get.side_effect = [
        MockResponse({"data": {"is_valid": True,"user_id": "123"}}, 200),
        MockResponse({"id": "123","email": "user248@example.com","name": "my_name"}, 200)
    ]

    another_user = User.objects.create_user(
        username="my_name",
        email="user248@example.com",
        password="somePassword248"
    )

    user, token = authenticated_user
    client = APIClient()
    client.credentials(HTTP_AUTHORIZATION=f"Token {token}")
    url = reverse('auth:facebook_link')

    payload = {
        "fbAccessToken": "1111111111"
    }

    response = client.post(url, payload, format="json")
    assert response.status_code == 400
    assert response.json() == {"error": "Email use by other user"}


@pytest.mark.django_db
@patch('requests.get')
def test_facebook_link_already_linked(mock_get, authenticated_user):
    """
        # Social network already linked
        # Ensure get response error {"error": "Social network already linked"}
    """
    mock_get.side_effect = [
        MockResponse({"data": {"is_valid": True,"user_id": "123"}}, 200),
        MockResponse({"id": "123","email": "user248@example.com","name": "my_name"}, 200)
    ]

    user, token = authenticated_user
    client = APIClient()
    client.credentials(HTTP_AUTHORIZATION=f"Token {token}")
    url = reverse('auth:facebook_link')

    SocialNetwork.objects.create(
        user=user,
        type="facebook",
        email="user248@example.com",
        name="my_name",
        social_id="111111"
    )

    payload = {
        "fbAccessToken": "1111111111"
    }

    response = client.post(url, payload, format="json")
    assert response.status_code == 400
    assert response.json() == {"error": "Social network already linked"}


@pytest.mark.django_db
@patch('requests.get')
def test_facebook_link_success(mock_get, authenticated_user):
    """
        # Mock valid responses from fb
        # Ensure get response {'id': 5}
    """
    mock_get.side_effect = [
        MockResponse({"data": {"is_valid": True,"user_id": "1111111"}}, 200),
        MockResponse({"id": "111111","email": "user123@example.com","name": "my_name"}, 200)
    ]

    user, token = authenticated_user
    client = APIClient()
    client.credentials(HTTP_AUTHORIZATION=f"Token {token}")
    url = reverse("auth:facebook_link")

    payload = {
        "fbAccessToken": "1111111111"
    }

    response = client.post(url, payload, format='json')
    assert response.status_code == 200
    data = response.json()
    assert UUID(data["id"]) == user.id
    assert SocialNetwork.objects.filter(user=user, social_id="111111").exists()