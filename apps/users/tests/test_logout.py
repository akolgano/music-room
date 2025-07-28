import pytest
from django.urls import reverse
from rest_framework.test import APIClient
from rest_framework.authtoken.models import Token
from django.contrib.auth import get_user_model

User = get_user_model()


@pytest.mark.django_db
@pytest.mark.parametrize("payload", [
    {},
    {"username": "user248"},
])
def test_logout_user_not_found(payload):
    """
        # Invalid username, or empty
        # Ensure get response error {"detail": "User not found."}
    """
    user = User.objects.create_user(username="user123", password="somePassword123")
    token = Token.objects.create(user=user)

    client = APIClient()
    client.credentials(HTTP_AUTHORIZATION='Token ' + token.key)
    url = reverse("users:logout")

    response = client.post(url, payload, format="json")
    assert response.status_code == 404
    assert response.json() == {"detail": "User not found."}


@pytest.mark.django_db
def test_logout_success():
    """
        # Valid username
        # Ensure get response {"detail": "Logout successfully"}
    """
    user = User.objects.create_user(username="user123", password="somePassword123")
    token = Token.objects.create(user=user)

    client = APIClient()
    client.credentials(HTTP_AUTHORIZATION='Token ' + token.key)
    url = reverse("users:logout")

    payload = {
        "username": "user123"
    }

    response = client.post(url, payload, format="json")
    assert response.status_code == 200
    assert response.json() == {"detail": "Logout successfully"}
    assert not Token.objects.filter(user=user).exists()
