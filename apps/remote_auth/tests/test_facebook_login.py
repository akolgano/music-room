import pytest
from django.urls import reverse
from rest_framework.test import APIClient
from unittest.mock import patch
from conftest import MockResponse


@patch('requests.get')
def test_facebook_login_invalid_token(mock_get):
    """
        # Mock request with invalid fbAccessToken
        # Ensure get response error {"error": "Invalid Facebook access token"}
    """
    mock_get.return_value = MockResponse({"data": {"is_valid": False}}, 200)

    client = APIClient()
    url = reverse("auth:facebook_login")

    payload = {
        "fbAccessToken": "invalid_token"
    }

    response = client.post(url, payload, format="json")
    assert response.status_code == 400
    assert response.json() == {"error": "Invalid Facebook access token"}


@patch('requests.get')
def test_facebook_login_empty_token(mock_get):
    """
        # Empty payload
        # Ensure get response error {'error': 'Access token not provided'}
    """
    client = APIClient()
    url = reverse("auth:facebook_login")

    payload = {}

    response = client.post(url, payload, format="json")
    assert response.status_code == 400
    assert response.json() == {'error': 'Access token not provided'}


@patch('requests.get')
def test_facebook_login_missing_fb_email(mock_get):
    """
        # Mock responses from fb with missing email return
        # Ensure get response error {"error": "Invalid login credentials"}
    """
    mock_get.side_effect = [
        MockResponse({"data": {"is_valid": True, "user_id": "123"}}, 200),
        MockResponse({"id": "123", "name": "my_name"}, 200)
    ]

    client = APIClient()
    url = reverse('auth:facebook_login')

    payload = {
        "fbAccessToken": "1111111111"
    }

    response = client.post(url, payload, format='json')
    assert response.status_code == 400
    assert response.json() == {"error": "Invalid login credentials"}


@pytest.mark.django_db
@patch('requests.get')
def test_facebook_login_success(mock_get):
    """
        # Mock valid responses from fb
        # Ensure get response {'token': '*******', 'user': {'email': 'user123@example.com', 'id': 2, 'username': 'my_name'}}
    """
    mock_get.side_effect = [
        MockResponse({"data": {"is_valid": True,"user_id": "123"}}, 200),
        MockResponse({"id": "123","email": "user123@example.com","name": "my_name"}, 200)
    ]

    client = APIClient()
    url = reverse('auth:facebook_login')

    payload = {
        "fbAccessToken": "1111111111"
    }

    response = client.post(url, payload, format='json')
    assert response.status_code == 200
    data = response.json()
    assert data['user']['username'] == "my_name"
    assert data['user']['email'] == "user123@example.com"