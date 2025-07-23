import pytest
from django.urls import reverse
from rest_framework.test import APIClient
from django.contrib.auth.models import User
from unittest.mock import patch


@pytest.mark.django_db
def test_user_password_change_missing_fields(authenticated_user):
    """
        # Missing current_password, new_password or all
        # Ensure get response error {'error': 'No current password or new password provided'}
    """
    user, token = authenticated_user
    client = APIClient()
    client.credentials(HTTP_AUTHORIZATION=f"Token {token}")
    url = reverse("users:user_password_change")

    payload = {
        "new_password": "newPass123"
    }

    response = client.post(url, payload, format="json")
    assert response.status_code == 400
    assert response.json() == {'error': 'No current password or new password provided'}

    payload = {
        "current_password": "wrongpass123",
    }

    response = client.post(url, payload, format="json")
    assert response.status_code == 400
    assert response.json() == {'error': 'No current password or new password provided'}

    payload = {}

    response = client.post(url, payload, format="json")
    assert response.status_code == 400
    assert response.json() == {'error': 'No current password or new password provided'}


@pytest.mark.django_db
def test_user_password_change_wrong_current_password(authenticated_user):
    """
        # Wrong current_password input
        # Ensure get response error {'error': 'Current password not match'}
    """
    user, token = authenticated_user
    client = APIClient()
    client.credentials(HTTP_AUTHORIZATION=f"Token {token}")
    url = reverse("users:user_password_change")

    payload = {
        "current_password": "wrongpass123",
        "new_password": "newPass123"
    }

    response = client.post(url, payload, format="json")
    assert response.status_code == 400
    assert response.json() == {'error': 'Current password not match'}


@pytest.mark.django_db
def test_user_password_change_unusable_password(authenticated_user):
    """
        # User set unusable password, cannot be changed
        # Ensure get response error {'error': 'User password cannot be change'}
    """
    user, token = authenticated_user
    client = APIClient()
    client.credentials(HTTP_AUTHORIZATION=f"Token {token}")
    url = reverse("users:user_password_change")
    user.set_unusable_password()
    user.save()

    payload = {
        "current_password": "wrongpass123",
        "new_password": "newPass123"
    }

    response = client.post(url, payload, format="json")
    assert response.status_code == 400
    assert response.json() == {'error': 'User password cannot be change'}


@pytest.mark.django_db
def test_user_password_change_success(authenticated_user):
    """
        # User valid input - change success
        # Ensure get response {'email': 'user123@example.com', 'username': 'user123'}
    """
    user, token = authenticated_user
    client = APIClient()
    client.credentials(HTTP_AUTHORIZATION=f"Token {token}")
    url = reverse("users:user_password_change")

    payload = {
        "current_password": "somePassword123",
        "new_password": "newPass123"
    }

    response = client.post(url, payload, format="json")
    assert response.status_code == 201
    data = response.json()
    assert data["username"] == user.username
    assert data["email"] == user.email
    