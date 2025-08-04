import pytest
from django.urls import reverse
from rest_framework.test import APIClient
from apps.users.tests.conftest import authenticated_user
from apps.profile.tests.conftest import user_init_profile, make_image_file


@pytest.mark.django_db
def test_delete_avatar_no_avatar(authenticated_user):
    """
        # No avatar in user profile
        # Ensure response error {'detail': 'No avatar to delete.'}
    """
    user, token = authenticated_user
    client = APIClient()
    client.credentials(HTTP_AUTHORIZATION=f"Token {token}")
    url = reverse("profile:delete-avatar")

    response = client.delete(url)
    assert response.status_code == 400
    assert response.json() == {'detail': 'No avatar to delete.'}


@pytest.mark.django_db
def test_delete_avatar(authenticated_user):
    """
        # Delete avatar in user profile
        # Ensure response status code == 204
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

    url = reverse("profile:delete-avatar")
    response = client.delete(url)
    assert response.status_code == 204