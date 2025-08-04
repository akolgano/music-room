import pytest
from django.urls import reverse
from rest_framework.test import APIClient
from apps.users.tests.conftest import authenticated_user
from apps.profile.models import MusicPreference


@pytest.mark.django_db
def test_music_preferences_list(authenticated_user):
    """
        # Create music prefernces and returns it
        # Ensure response contains created music preferences
    """
    user, token = authenticated_user
    client = APIClient()
    client.credentials(HTTP_AUTHORIZATION=f"Token {token}")
    url = reverse("profile:music-preferences-list")

    p1 = MusicPreference.objects.create(name="rock")
    p2 = MusicPreference.objects.create(name="jazz")
    p3 = MusicPreference.objects.create(name="pop")

    response = client.get(url)
    assert response.status_code == 200
    data = response.json()
    prefs_ids = [item["id"] for item in data]
    assert p1.id in prefs_ids
    assert p2.id in prefs_ids
    assert p3.id in prefs_ids
    prefs_names = [item["name"] for item in data]
    assert p1.name in prefs_names
    assert p2.name in prefs_names
    assert p3.name in prefs_names