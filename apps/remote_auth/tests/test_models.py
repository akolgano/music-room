import pytest
from apps.remote_auth.models import SocialNetwork
from django.contrib.auth.models import User


@pytest.mark.django_db
def test_create_socialnetwork():

    email = "user248@example.com"
    type = "facebook"
    social_id = "111111111"

    user = User.objects.create_user(
        username="my_name",
        email="user248@example.com",
        password="somePassword248"
    )

    social_network = SocialNetwork.objects.create(
        email = email,
        type = type,
        social_id = social_id,
        user = user
    )

    assert social_network.email == email
    assert social_network.type == type
    assert social_network.social_id == social_id
    assert social_network.user == user