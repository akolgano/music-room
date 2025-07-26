import pytest
from rest_framework.test import APIClient
from django.urls import reverse
from unittest.mock import patch
from apps.remote_auth.models import SocialNetwork
from django.contrib.auth import get_user_model

User = get_user_model()


@pytest.mark.django_db
@pytest.mark.parametrize("payload", [
    {"email": "user123@gmail.com"},
    {"email": "social123@gmail.com"},
])
def test_check_email_exists(payload):
    """
        # Payload with existing email in User or SocialNetwork
    """
    user = User.objects.create_user(username='user123', email="user123@gmail.com", password='somePassword123')
    SocialNetwork.objects.create(email="social123@gmail.com", user=user, type='google', social_id='111111', name='user248')

    client = APIClient()
    url = reverse('users:check_email')

    response = client.post(url, payload, format='json')
    assert response.status_code == 200
    assert response.json() == {'exists': True}

    response = client.post(url, {"email": "no_user@gmail.com"}, format='json')
    assert response.status_code == 200
    assert response.json() == {'exists': False}