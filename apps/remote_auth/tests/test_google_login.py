import pytest
from django.urls import reverse
from rest_framework.test import APIClient
from unittest.mock import patch


@patch('google.oauth2.id_token.verify_oauth2_token')
def test_google_login_invalid_token(mock_verify):
    """
        # Mock id_token.verify_oauth2_token with invalid idToken
        # Ensure get response error {"error": "Invalid idToken"}
    """
    mock_verify.side_effect = ValueError("Invalid token")

    client = APIClient()
    url = reverse('auth:google_login')

    payload = {
        "idToken": "invalid_token"
    }

    response = client.post(url, payload, format="json")
    assert response.status_code == 400
    assert response.json() == {"error": "Invalid idToken"}


def test_google_login_empty():
    """
        # Empty payload
        # Ensure get response error {'error': 'Invalid social username'}
    """
    client = APIClient()
    url = reverse('auth:google_login')

    payload = {}

    response = client.post(url, payload, format="json")
    assert response.status_code == 400
    assert response.json() == {'error': 'Invalid social username'}


def test_google_login_missing_social_id():
    """
        # No id_token, missing socialId in payload
        # Ensure get response error {'error': 'Invalid social id'}
    """
    client = APIClient()
    url = reverse('auth:google_login')

    payload = {
        "socialName": "my_name",
        "socialEmail": "user123@example.com"
    }

    response = client.post(url, payload, format="json")
    assert response.status_code == 400
    assert response.json() == {'error': 'Invalid social id'}


def test_google_login_missing_social_name():
    """
        # No id_token, missing socialName in payload
        # Ensure get response error {'error': 'Invalid social username'}
    """
    client = APIClient()
    url = reverse('auth:google_login')

    payload = {
        "socialId": "111111",
        "socialEmail": "user123@example.com"
    }

    response = client.post(url, payload, format="json")
    assert response.status_code == 400
    assert response.json() == {'error': 'Invalid social username'}


def test_google_login_missing_social_email():
    """
        # No id_token, missing socialEmail in payload
        # Ensure get response error {'error': 'Invalid social email'}
    """
    client = APIClient()
    url = reverse('auth:google_login')

    payload = {
        "socialId": "111111",
        "socialName": "my_name"
    }

    response = client.post(url, payload, format="json")
    assert response.status_code == 400
    assert response.json() == {'error': 'Invalid social email'}


@pytest.mark.django_db
@patch('google.oauth2.id_token.verify_oauth2_token')
def test_google_login_id_token_success(mock_verify):
    """
        # Mock id_token.verify_oauth2_token with valid idToken
        # Ensure get response {'token': '******', 'user': {'email': 'user123@example.com', 'id': 7, 'username': 'my_name'}}
    """
    mock_verify.return_value = {
        'email': 'user123@example.com',
        'name': 'my_name',
        'sub': '111111'
    }

    client = APIClient()
    url = reverse('auth:google_login')

    payload = {
        "idToken": "valid_token"
    }

    response = client.post(url, payload, format="json")
    assert response.status_code == 200
    data = response.json()
    assert data['user']['username'] == "my_name"
    assert data['user']['email'] == "user123@example.com"


@pytest.mark.django_db
def test_google_login_no_id_token_success():
    """
        # No idToken, but with valid payload
        # Ensure get response {'token': '******', 'user': {'email': 'user123@example.com', 'id': 7, 'username': 'my_name'}}
    """

    client = APIClient()
    url = reverse('auth:google_login')

    payload = {
        "socialId": "111111",
        "socialName": "my_name",
        "socialEmail": "user123@example.com"
    }

    response = client.post(url, payload, format="json")
    assert response.status_code == 200
    data = response.json()
    assert data['user']['username'] == "my_name"
    assert data['user']['email'] == "user123@example.com"