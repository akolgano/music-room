import pytest
from rest_framework.authtoken.models import Token
from django.contrib.auth import get_user_model

User = get_user_model()


@pytest.fixture
def authenticated_user(db):
    user = User.objects.create_user(
        username="user123",
        email="user123@example.com",
        password="somePassword123"
    )
    token, _ = Token.objects.get_or_create(user=user)
    return user, token.key