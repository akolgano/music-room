import pytest
from django.urls import reverse
from rest_framework.test import APIClient
from unittest.mock import patch

from django.contrib.auth import get_user_model


User = get_user_model()

@pytest.mark.django_db
def test_forgot_password_no_email():
    """
        # Empty email
        # Ensure get response error {'error': 'No email provided'}
    """
    client = APIClient()
    url = reverse("users:forgot_password")

    payload = {}

    response = client.post(url, payload, format="json")
    assert response.status_code == 400
    assert response.json() == {'error': 'No email provided'}


@pytest.mark.django_db
def test_forgot_password_no_user():
    """
        # No user with this email
        # Ensure get response error {'error': 'User not found'}
    """
    client = APIClient()
    url = reverse("users:forgot_password")

    payload = {
        "email": "user123@exampe.com"
    }

    response = client.post(url, payload, format="json")
    assert response.status_code == 404
    assert response.json() == {'error': 'User not found'}


@pytest.mark.django_db
def test_forgot_password_unusable_password():
    """
        # User with unusable password - cannot be reset
        # Ensure get response error {'error': 'User passwords cannot be reset'}
    """
    client = APIClient()
    url = reverse("users:forgot_password")

    user = User.objects.create_user(
        username = 'user123',
        password = "somePassword123",
        email = 'user123@example.com'
    )
    user.set_unusable_password()
    user.save()

    payload = {
        "email": "user123@example.com"
    }

    response = client.post(url, payload, format="json")
    assert response.status_code == 400
    assert response.json() == {'error': 'User passwords cannot be reset'}


@pytest.mark.django_db
@patch("apps.users.views.utils.create_otp_for_user", return_value=None)
def test_forgot_password_otp_creation_fail(mock_create_otp):
    """
        # Mock OTP creation return None
        # Ensure get response error {'error': 'OTP creation failed'}
    """
    client = APIClient()
    url = reverse("users:forgot_password")

    user = User.objects.create_user(
        username = 'user123',
        password = "somePassword123",
        email = "user123@example.com"
    )

    payload = {
        "email": "user123@example.com"
    }

    response = client.post(url, payload, format="json")
    assert response.status_code == 404
    assert response.json() == {'error': 'OTP creation failed'}


@pytest.mark.django_db
@patch("apps.users.views.utils.create_otp_for_user", return_value="123456")
@patch("apps.users.views.email_sender.send_forgot_password_email", side_effect=Exception("SMTP"))
def test_forgot_password_email_send_fail(mock_send_email, mock_create_otp):
    """
        # Mock email sending fail
        # Ensure get response error {'error': 'OTP email sending failed'}
    """
    client = APIClient()
    url = reverse("users:forgot_password")

    user = User.objects.create_user(
        username = 'user123',
        password = "somePassword123",
        email = "user123@example.com"
    )

    payload = {
        "email": "user123@example.com"
    }

    response = client.post(url, payload, format="json")
    assert response.status_code == 400
    assert response.json() == {'error': 'OTP email sending failed'}


@pytest.mark.django_db
@patch("apps.users.views.utils.create_otp_for_user", return_value="123456")
@patch("apps.users.views.email_sender.send_forgot_password_email")
def test_forgot_password_success(mock_send_email, mock_create_otp):
    """
        # Mock OTP creation and email sending success
        # Ensure get response {'email': 'user123@example.com', 'username': 'user123'}
    """
    client = APIClient()
    url = reverse("users:forgot_password")

    email = 'user123@example.com'

    user = User.objects.create_user(
        username = "user123",
        password = "somePassword123",
        email = email
    )

    payload = {
        "email": "user123@example.com"
    }

    response = client.post(url, payload, format="json")
    assert response.status_code == 201
    data = response.json()
    assert data["email"] == email
