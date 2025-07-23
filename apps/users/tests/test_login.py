import pytest
from django.urls import reverse
from rest_framework.test import APIClient
from django.contrib.auth.models import User
from rest_framework.authtoken.models import Token

@pytest.mark.django_db
def test_login_missing_fields():
    """
        # Missing username, password, or both
        # Ensure get response error {'detail': 'Username or password not provided'}
    """
    client = APIClient()
    url = reverse("users:login")

    payload = {
        "username": "user123"
    }

    response = client.post(url, payload, format="json")
    assert response.status_code == 404
    assert response.json() == {'detail': 'Username or password not provided'}

    payload = {
        "password": "strongPassword123"
    }

    response = client.post(url, payload, format="json")
    assert response.status_code == 404
    assert response.json() == {'detail': 'Username or password not provided'}

    payload = {}

    response = client.post(url, payload, format="json")
    assert response.status_code == 404
    assert response.json() == {'detail': 'Username or password not provided'}


@pytest.mark.django_db
def test_login_no_user():
    """
        # User not in system
        # Ensure get response error {"detail": "User not found."}
    """
    client = APIClient()
    url = reverse("users:login")

    payload = {
        "username": "user123",
        "password": "strongPassword123"
    }

    response = client.post(url, payload, format="json")
    assert response.status_code == 404
    assert response.json() == {"detail": "User not found."}


@pytest.mark.django_db
def test_login_incorrect_password():
    """
        # User incorrect password
        # Ensure get response error {"detail": "Not found."}
    """
    client = APIClient()
    url = reverse("users:login")

    user = User.objects.create_user(
        username = "user123",
        password = "somePassword123",
        email = "user123@example.com"
    )

    payload = {
        "username": "user123",
        "password": "somePassword248"
    }

    response = client.post(url, payload, format="json")
    assert response.status_code == 404
    assert response.json() == {"detail": "Not found."}


@pytest.mark.django_db
def test_login_success():
    """
        # Correct user login username, password
        # Ensure get response {'token': '*********', 'user': {'email': 'user123@example.com', 'id': 3, 'username': 'user123'}}
    """
    client = APIClient()
    url = reverse("users:login")

    password = "somePassword123"
    username = "user123"

    user = User.objects.create_user(
        username = username,
        password = password,
        email = "user123@example.com"
    )

    payload = {
        "username": username,
        "password": password
    }

    response = client.post(url, payload, format="json")
    assert response.status_code == 200
    data = response.json()
    assert "token" in data
    assert data["user"]["username"] == username
    assert Token.objects.filter(user=user).exists()