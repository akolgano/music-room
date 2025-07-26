from apps.users.serializers import UserSerializer
import pytest
from django.core.exceptions import ValidationError as DjangoValidationError
from django.contrib.auth import get_user_model


User = get_user_model()


@pytest.mark.django_db
def test_user_serializer_valid_data():
    """
        # Create a valid user
    """
    data = {
        "username": "user123",
        "email": "test@example.com",
        "password": "user123456"
    }
    serializer = UserSerializer(data=data)
    assert serializer.is_valid()

    user = serializer.save()
    assert user.username == "user123"
    assert user.email == "test@example.com"
    assert user.check_password("user123456")


@pytest.mark.django_db
def test_user_serializer_username_taken():
    """
        # Create a user with username "user123"
        # Create another user with same username "user123"
        # Ensure get response error "Username is already taken."
    """
    User.objects.create_user(username="user123", email="other@example.com", password="password")

    data = {
        "username": "user123",
        "email": "new@example.com",
        "password": "StrongPass123!"
    }
    serializer = UserSerializer(data=data)
    assert not serializer.is_valid()
    assert "username" in serializer.errors
    assert serializer.errors["username"][0] == "Username is already taken."


@pytest.mark.django_db
def test_user_serializer_email_taken():
    """
        # Create a user with email "user123@example.com"
        # Create another user with same email "user123@example.com"
        # Ensure get response error "Email is already taken."
    """
    User.objects.create_user(username="user123", email="user123@example.com", password="password123")

    data = {
        "username": "user248",
        "email": "user123@example.com",
        "password": "password248"
    }
    serializer = UserSerializer(data=data)
    assert not serializer.is_valid()
    assert "email" in serializer.errors
    assert serializer.errors["email"][0] == "Email is already taken."


@pytest.mark.django_db
def test_user_serializer_email_invalid_format():
    """
        # Create a user with invalid email
        # Ensure get response error "Enter a valid email address."
    """
    data = {
        "username": "user123",
        "email": "invalid#gmail.com",
        "password": "password123!"
    }
    serializer = UserSerializer(data=data)
    assert not serializer.is_valid()
    assert "email" in serializer.errors
    assert "Enter a valid email address." in serializer.errors["email"]


@pytest.mark.django_db
def test_user_serializer_password_too_short():
    """
        # Create a user with password length less than 8 characters
        # Ensure get response error "Ensure this field has at least 8 characters."
    """
    data = {
        "username": "user123",
        "email": "user123@example.com",
        "password": "123"
    }
    serializer = UserSerializer(data=data)
    assert not serializer.is_valid()
    assert "password" in serializer.errors
    assert any("Ensure this field has at least 8 characters." in msg for msg in serializer.errors["password"])


@pytest.mark.django_db
def test_user_serializer_password_weak():
    """
        # Create a user with a weak password - 12345678
        # Ensure get response error "This password is too common."
    """
    data = {
        "username": "user123",
        "email": "user123@example.com",
        "password": "12345678"
    }
    serializer = UserSerializer(data=data)
    assert not serializer.is_valid()
    assert "password" in serializer.errors
    assert any("This password is too common." in msg for msg in serializer.errors["password"])