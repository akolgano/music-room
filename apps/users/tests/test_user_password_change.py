import pytest
from django.urls import reverse
from rest_framework.test import APIClient
from unittest.mock import patch
from django.contrib.auth import get_user_model

User = get_user_model()

@pytest.mark.django_db
@pytest.mark.parametrize("payload", [
    {},
    {"new_password": "newPass123"},
    {"current_password": "wrongpass123"},
])
def test_user_password_change_missing_fields(authenticated_user, payload):
    """
        # Missing current_password, new_password or all
        # Ensure get response error {'error': 'No current password or new password provided'}
    """
    user, token = authenticated_user
    client = APIClient()
    client.credentials(HTTP_AUTHORIZATION=f"Token {token}")
    url = reverse("users:user_password_change")

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
    