import pytest
from django.urls import reverse
from rest_framework.test import APIClient
from rest_framework.authtoken.models import Token
from django.contrib.auth import get_user_model


User = get_user_model()

def test_log_activity_success():
    """
        # Valid log data
        # Ensure get status 200
    """
    client = APIClient()
    url = reverse("users:log_activity")

    payload = {
        "logs": [
            {
                "action": "login",
                "screen": "auth",
                "timestamp": "2025-08-18T12:10:00Z",
                "platform": "mobile",
                "user_id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
                "metadata": {
                    "any1": "any1",
                    "any2": "any2",
                    "any3": "any3"
                }
            }
        ]
    }

    response = client.post(url, payload, format="json")
    assert response.status_code == 200


def test_log_activity_error():
    """
        # Invalid log data
        # Ensure get status 500
    """
    client = APIClient()
    url = reverse("users:log_activity")

    payload = []

    response = client.post(url, payload, format="json")
    assert response.status_code == 500
