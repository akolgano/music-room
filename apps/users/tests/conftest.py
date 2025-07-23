import pytest
from django.contrib.auth.models import User
from rest_framework.authtoken.models import Token

@pytest.fixture
def authenticated_user(db):
    user = User.objects.create_user(
        username="user123",
        email="user123@example.com",
        password="somePassword123"
    )
    token, _ = Token.objects.get_or_create(user=user)
    return user, token.key