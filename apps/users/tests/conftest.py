import pytest
from rest_framework.authtoken.models import Token
from django.contrib.auth import get_user_model
from apps.profile.models import Profile


User = get_user_model()


@pytest.fixture
def authenticated_user(db):
    user = User.objects.create_user(
        username="user123",
        email="user123@example.com",
        password="somePassword123"
    )
    Profile.objects.create(user=user)
    token, _ = Token.objects.get_or_create(user=user)
    return user, token.key