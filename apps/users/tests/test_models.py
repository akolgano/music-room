import pytest
from django.contrib.auth.hashers import make_password
from apps.users.models import OneTimePasscode, SignupOneTimePasscode
from django.utils import timezone
from datetime import timedelta
from django.contrib.auth import get_user_model

User = get_user_model()

@pytest.mark.django_db
def test_create_user():

    password = "123456"

    user = User.objects.create_user(
        username = "jane",
        password = password,
        email = "test@example.com"
        )

    assert user.username == "jane"
    assert user.check_password("123456")
    assert user.email == "test@example.com"


@pytest.mark.django_db
def test_create_one_time_passcode():

    user = User.objects.create_user(
        username="user123",
        email="user123@example.com",
        password="somePassword123"
    )

    one_time_passcode = OneTimePasscode.objects.create(
        user=user,
        code=make_password("123456"), 
        expired_at=timezone.now() + timezone.timedelta(minutes=5)
    )

    assert one_time_passcode.user == user


@pytest.mark.django_db
def test_create_signup_one_time_passcode():

    email = "user123@example.com"

    signup_one_time_passcode = SignupOneTimePasscode.objects.create(
        email=email,
        code=make_password("123456"),
        expired_at=timezone.now() + timedelta(minutes=5)
    )

    assert signup_one_time_passcode.email == email
