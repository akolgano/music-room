import pytest
from django.urls import reverse
from rest_framework import status
from unittest.mock import patch
from rest_framework.test import APIClient


@pytest.mark.django_db
def test_signup_email_otp_no_email():
    """
        # Empty email params
        # Ensure get response error {'error': 'No email provided'}
    """
    client = APIClient()
    url = reverse("users:signup_email_otp")

    payload = {}

    response = client.post(url, payload, format="json")

    assert response.status_code == 400
    assert response.json() == {'error': 'No email provided'}


@pytest.mark.django_db
def test_signup_email_otp_invalid_email():
    """
        # Invalid email
        # Ensure get response error {'error': 'Invalid email format'}
    """
    client = APIClient()
    url = reverse("users:signup_email_otp")

    payload = {
        "email": "user123#example.com"
    }

    response = client.post(url, payload, format="json")

    assert response.status_code == 400
    assert response.json() == {'error': 'Invalid email format'}


@pytest.mark.django_db
@patch("apps.users.views.utils.create_otp_signup", return_value=None)
def test_signup_email_otp_otp_creation_failed(mock_create_otp):
    """
        # Mock otp creation failed
        # Ensure get response error {'error': 'Signup OTP creation failed'}
    """
    client = APIClient()
    url = reverse("users:signup_email_otp")

    payload = {
        "email": "user123@example.com"
    }

    response = client.post(url, payload, format="json")
    assert response.status_code == 400
    assert response.json() == {"error": "Signup OTP creation failed"}


@pytest.mark.django_db
@patch("apps.users.views.utils.create_otp_signup", return_value="123456")
@patch("apps.users.views.email_sender.send_signup_otp_email", side_effect=Exception("fail"))
def test_signup_email_otp_email_send_failed(mock_send_email, mock_create_otp):
    """
        # Mock otp creation
        # Mock sending email fail
        # Ensure get response error {"error": "Signup OTP email sending failed"}
    """
    client = APIClient()
    url = reverse("users:signup_email_otp")

    payload = {
        "email": "user123@example.com"
    }

    response = client.post(url, payload, format="json")
    assert response.status_code == 400
    assert response.json() == {"error": "Signup OTP email sending failed"}


@pytest.mark.django_db
@patch("apps.users.views.email_sender.send_signup_otp_email")
@patch("apps.users.views.utils.create_otp_signup", return_value="123456")
def test_signup_email_otp_success(mock_create_otp, mock_send_email):
    """
        # Mock otp creation
        # Mock sending email success
        # Ensure get status code 201
    """

    client = APIClient()
    url = reverse("users:signup_email_otp")
    email = "user123@example.com"

    payload = {
        "email": "user123@example.com"
    }
    
    response = client.post(url, payload, format="json")
    assert response.status_code == status.HTTP_201_CREATED
    assert response.json() == {"email": email}
    mock_create_otp.assert_called_once_with(email)
    mock_send_email.assert_called_once_with("123456", email)