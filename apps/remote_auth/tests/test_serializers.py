import pytest
from apps.remote_auth.serializers import RemoteUserSerializer
from django.contrib.auth import get_user_model


User = get_user_model()


@pytest.mark.django_db
def test_remote_user_serializer_space_in_username():
    """
        # Spaces in username
        # Ensure get error - "Username cannot have leading or trailing spaces."
    """
    payload = {
        "username": " user123  ",
        "email": "user123@example.com"
    }
    serializer = RemoteUserSerializer(data=payload)
    assert not serializer.is_valid()
    assert "username" in serializer.errors
    assert serializer.errors["username"][0] == "Username cannot have leading or trailing spaces."


@pytest.mark.django_db
def test_remote_user_serializer_username_in_use():
    """
        # Username already in use
        # Ensure get error - "Username is already taken."
    """
    User.objects.create(username="user123", email="user123@example.com")
    
    payload = {
        "username": "user123",
        "email": "user123@example.com"
    }
    serializer = RemoteUserSerializer(data=payload)
    assert not serializer.is_valid()
    assert "username" in serializer.errors
    assert serializer.errors["username"][0] == "Username is already taken."


@pytest.mark.django_db
def test_remote_user_serializer_invalid_email_format():
    """
        # Invalid email format
        # Ensure get error - "Enter a valid email address."
    """
    payload = {
        "username": "user123",
        "email": "user123##example.com"
    }
    serializer = RemoteUserSerializer(data=payload)
    assert not serializer.is_valid()
    assert "email" in serializer.errors
    assert serializer.errors["email"][0] == "Enter a valid email address."


@pytest.mark.django_db
def test_remote_user_serializer_email_in_use():
    """
        # Invalid email in use
        # Ensure get error - "Email is already taken."
    """
    User.objects.create(username="user123", email="user123@example.com")
    
    payload = {
        "username": "user248",
        "email": "user123@example.com"
    }

    serializer = RemoteUserSerializer(data=payload)
    assert not serializer.is_valid()
    assert "email" in serializer.errors
    assert serializer.errors["email"][0] == "Email is already taken."


@pytest.mark.django_db
def test_remote_user_serializer_success():
    """
        # Valid username, email
        # Ensure user added
    """
    payload = {
        "username": "user123",
        "email": "user123@example.com"
    }

    serializer = RemoteUserSerializer(data=payload)
    assert serializer.is_valid()
    user = serializer.save()
    assert user.username == "user123"
    assert user.email == "user123@example.com"