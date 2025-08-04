import pytest
from django.urls import reverse
from rest_framework.test import APIClient
from apps.users.tests.conftest import authenticated_user
from apps.profile.tests.conftest import user_init_profile, make_image_file
import uuid
from apps.profile.models import VisibilityChoices, MusicPreference


def test_update_profile_unauthenticated():
    """
        # Unauthenticated user
        # Ensure response error {'detail': 'Authentication credentials were not provided.'}
    """
    client = APIClient()
    url = reverse("profile:profile-update")

    response = client.patch(url)
    assert response.status_code == 401
    assert response.json() == {'detail': 'Authentication credentials were not provided.'}
    
    response = client.put(url)
    assert response.status_code == 401
    assert response.json() == {'detail': 'Authentication credentials were not provided.'}


@pytest.mark.django_db
def test_update_profile_upload_avatar(authenticated_user):
    """
        # Upload a PNG image
        # Ensure response avatar is not empty
    """
    image = make_image_file()

    user, token = authenticated_user
    client = APIClient()
    client.credentials(HTTP_AUTHORIZATION=f"Token {token}")
    url = reverse("profile:profile-update")

    payload = {
        "avatar": image
    }

    response = client.patch(url, payload, format="multipart")
    assert response.status_code == 200
    data = response.json()
    assert "avatar" in data
    assert data["avatar"]


@pytest.mark.django_db
def test_update_profile(authenticated_user):
    """
        # Valid payload
        # Ensure response contains all inputs in payload
    """
    image = make_image_file()

    user, token = authenticated_user
    client = APIClient()
    client.credentials(HTTP_AUTHORIZATION=f"Token {token}")
    url = reverse("profile:profile-update")

    MusicPreference.objects.create(name="rock")
    prefs = MusicPreference.objects.filter(name="rock").first()

    payload = {
        "avatar": image,
        "name": "user248",
        "name_visibility": VisibilityChoices.PRIVATE,
        "location": "Singapore",
        "location_visibility": VisibilityChoices.PUBLIC,
        "bio": "bio",
        "bio_visibility": VisibilityChoices.PUBLIC,
        "phone": "+6598989898",
        "phone_visibility": VisibilityChoices.PRIVATE,
        "friend_info": "Hello Friend !",
        "friend_info_visibility": VisibilityChoices.FRIENDS,
        "music_preferences_ids": prefs.id,
        "music_preferences_visibility": VisibilityChoices.PUBLIC
    }

    response = client.patch(url, payload, format="multipart")
    assert response.status_code == 200
    data = response.json()
    assert "avatar" in data
    assert data["avatar"]
    assert data["name"] == "user248"
    assert data["name_visibility"] == VisibilityChoices.PRIVATE
    assert data["location"] == "Singapore"
    assert data["location_visibility"] == VisibilityChoices.PUBLIC
    assert data["bio"] == "bio"
    assert data["bio_visibility"] == VisibilityChoices.PUBLIC
    assert data["phone"] == "+6598989898"
    assert data["phone_visibility"] == VisibilityChoices.PRIVATE
    assert data["friend_info"] == "Hello Friend !"
    assert data["friend_info_visibility"] == VisibilityChoices.FRIENDS
    assert 'rock' in set(data["music_preferences"])
    assert data["music_preferences_visibility"] == VisibilityChoices.PUBLIC