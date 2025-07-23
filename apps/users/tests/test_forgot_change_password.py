import pytest
from django.urls import reverse
from rest_framework.test import APIClient
from django.contrib.auth.models import User
from unittest.mock import patch
from django.contrib.auth.hashers import make_password
from apps.users.models import OneTimePasscode
from django.utils import timezone
from datetime import timedelta


@pytest.mark.django_db
@pytest.mark.parametrize("payload", [
    {},
    {"email": "user123@example.com", "otp": "123456"},
    {"email": "user123@example.com"},
    {"otp": "123456", "password": "somePassword123"},
])
def test_forgot_change_password_missing_fields(payload):
    """
        # Missing email, otp, password or all
        # Ensure get response error {'error': 'Invalid email, otp or password'}
    """
    client = APIClient()
    url = reverse("users:forgot_change_password")

    response = client.post(url, payload, format="json")
    assert response.status_code == 400
    assert response.json() == {'error': 'Invalid email, otp or password'}


@pytest.mark.django_db
def test_forgot_change_password_user_not_found():
    """
        # Email does not belong to any user
        # Ensure get response error {'error': 'User not found'}
    """
    client = APIClient()
    url = reverse("users:forgot_change_password")

    payload = {
        "email": "user123@example.com",
        "otp": "123456",
        "password": "somePassword123"
    }

    response = client.post(url, payload, format="json")
    assert response.status_code == 404
    assert response.json() == {'error': 'User not found'}


@pytest.mark.django_db
def test_forgot_change_password_unusable_password():
    """
        # User password is unusable
        # Ensure get response error {'error': 'User passwords cannot be reset'}
    """
    client = APIClient()
    url = reverse("users:forgot_change_password")

    user = User.objects.create_user(
        username = 'user123',
        password = "somePassword123",
        email = "user123@example.com"
    )
    user.set_unusable_password()
    user.save()

    payload = {
        "email": "user123@example.com",
        "otp": "123456",
        "password": "somePassword123"
    }

    response = client.post(url, payload, format="json")
    assert response.status_code == 400
    assert response.json() == {'error': 'User passwords cannot be reset'}


@pytest.mark.django_db
def test_forgot_change_password_otp_expired():
    """
        # Expired OTP
        # Ensure get response error {'error': 'OTP not found or expired'}
    """
    client = APIClient()
    url = reverse("users:forgot_change_password")

    user = User.objects.create_user(
        username = 'user123',
        password = "somePassword123",
        email = "user123@example.com"
    )

    OneTimePasscode.objects.create(
        user=user, 
        code=make_password("123456"), 
        expired_at=timezone.now() - timezone.timedelta(minutes=1)
    )

    payload = {
        "email": "user123@example.com",
        "otp": "123456",
        "password": "somePassword123"
    }

    response = client.post(url, payload, format="json")
    assert response.status_code == 400
    assert response.json() == {'error': 'OTP not found or expired'}


@pytest.mark.django_db
def test_forgot_change_password_wrong_otp():
    """
        # Wrong OTP
        # Ensure get response error {'error': 'OTP not match'}
    """
    client = APIClient()
    url = reverse("users:forgot_change_password")

    user = User.objects.create_user(
        username = 'user123',
        password = "somePassword123",
        email = "user123@example.com"
    )

    OneTimePasscode.objects.create(
        user=user, 
        code=make_password("123456"), 
        expired_at=timezone.now() + timezone.timedelta(minutes=5)
    )

    payload = {
        "email": "user123@example.com",
        "otp": "456789",
        "password": "somePassword123"
    }

    response = client.post(url, payload, format="json")
    assert response.status_code == 400
    assert response.json() == {'error': 'OTP not match'}


@pytest.mark.django_db
def test_forgot_change_password_success():
    """
        # Valid inputs
        # Ensure get response {'email': 'user123@example.com', 'username': 'user123'}
    """
    client = APIClient()
    url = reverse("users:forgot_change_password")
    email = "user123@example.com"

    user = User.objects.create_user(
        username = "user123",
        password = "somePassword123",
        email = email
    )

    OneTimePasscode.objects.create(
        user=user, 
        code=make_password("123456"), 
        expired_at=timezone.now() + timezone.timedelta(minutes=5)
    )

    payload = {
        "email": "user123@example.com",
        "otp": "123456",
        "password": "somePassword248"
    }

    response = client.post(url, payload, format="json")
    assert response.status_code == 201
    data = response.json()
    assert data["email"] == email