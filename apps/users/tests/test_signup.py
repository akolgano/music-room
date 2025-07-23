import pytest
from django.urls import reverse
from unittest.mock import patch
from rest_framework.test import APIClient
from rest_framework import status
from django.utils import timezone
from datetime import timedelta

from apps.users.models import SignupOneTimePasscode
from apps.remote_auth.models import SocialNetwork
from apps.profile.models import Profile
from django.contrib.auth.models import User
from rest_framework.authtoken.models import Token
from django.contrib.auth.hashers import make_password

@pytest.mark.django_db
def test_signup_success():
    """
        # Create otp
        # Ensure no social user exists with this email
        # Ensure user and token created
        # Ensure user profile created
    """
    client = APIClient()
    url = reverse("users:signup")

    email = "user123@example.com"
    otp_code = "123456"
    
    hashed_otp = make_password(otp_code)

    SignupOneTimePasscode.objects.create(
        email=email,
        code=hashed_otp,
        expired_at=timezone.now() + timedelta(minutes=5)
    )

    assert not SocialNetwork.objects.filter(email=email).exists()

    payload = {
        "email": email,
        "otp": otp_code,
        "username": "user123",
        "password": "strongPassword123"
    }

    response = client.post(url, payload, format="json")

    assert response.status_code == 201
    data = response.json()
    assert "token" in data
    assert data["user"]["email"] == email

    user = User.objects.get(email=email)
    assert Token.objects.filter(user=user).exists()

    profile = Profile.objects.get(user=user)
    assert profile is not None


@pytest.mark.django_db
def test_signup_email_in_socialnetwork():
    """
        # Create socialnetwork with same email
        # Ensure get response "error": "Email already in use"
    """
    client = APIClient()
    url = reverse("users:signup")

    email = "user123@example.com"
    otp_code = "123456"
    
    hashed_otp = make_password(otp_code)

    SignupOneTimePasscode.objects.create(
        email=email,
        code=hashed_otp,
        expired_at=timezone.now() + timedelta(minutes=5)
    )

    SocialNetwork.objects.create(
        email=email,
        type="facebook",
        social_id="111111",
        user_id=1
    )

    payload = {
        "email": email,
        "otp": otp_code,
        "username": "user123",
        "password": "strongPassword123"
    }

    response = client.post(url, payload, format="json")

    assert response.status_code == 404
    assert response.json() == {"error": "Email already in use"}


@pytest.mark.django_db
def test_signup_no_otp():
    """
        # No create OTP
        # Ensure get response "error": "Signup OTP not found or expired"  
    """
    client = APIClient()
    url = reverse("users:signup")

    email = "user123@example.com"
    otp_code = "123456"

    payload = {
        "email": email,
        "otp": otp_code,
        "username": "user123",
        "password": "strongPassword123"
    }

    response = client.post(url, payload, format="json")

    assert response.status_code == 404
    assert response.json() == {"error": "Signup OTP not found or expired"}


@pytest.mark.django_db
def test_signup_otp_not_match():
    """
        # Incorrect otp in payload
        # Ensure get response "error": "Signup OTP not match"
    """
    client = APIClient()
    url = reverse("users:signup")

    email = "user123@example.com"
    otp_code = "123456"
    otp_code2 = "111111"

    hashed_otp = make_password(otp_code)

    SignupOneTimePasscode.objects.create(
        email=email,
        code=hashed_otp,
        expired_at=timezone.now() + timedelta(minutes=5)
    )

    payload = {
        "email": email,
        "otp": otp_code2,
        "username": "user123",
        "password": "strongPassword123"
    }

    response = client.post(url, payload, format="json")

    assert response.status_code == 404
    assert response.json() == {"error": "Signup OTP not match"}


@pytest.mark.django_db
def test_signup_already_email_registered():
    """
        # Create otp
        # Ensure no social user exists with this email
        # Ensure user and token created
        # Ensure user profile created
        # Repeat the steps above to create another user with same email
        # Ensure get response "email": ["Email is already taken."] 
    """
    client = APIClient()
    url = reverse("users:signup")

    email = "user123@example.com"
    otp_code = "123456"
    
    hashed_otp = make_password(otp_code)

    SignupOneTimePasscode.objects.create(
        email=email,
        code=hashed_otp,
        expired_at=timezone.now() + timedelta(minutes=5)
    )

    assert not SocialNetwork.objects.filter(email=email).exists()

    payload = {
        "email": email,
        "otp": otp_code,
        "username": "user123",
        "password": "somePassword123"
    }

    response = client.post(url, payload, format="json")

    assert response.status_code == 201, response.json()
    data = response.json()
    assert "token" in data
    assert data["user"]["email"] == email

    user = User.objects.get(email=email)
    assert Token.objects.filter(user=user).exists()

    profile = Profile.objects.get(user=user)
    assert profile is not None

    # Repeat
    SignupOneTimePasscode.objects.create(
        email=email,
        code=hashed_otp,
        expired_at=timezone.now() + timedelta(minutes=5)
    )

    assert not SocialNetwork.objects.filter(email=email).exists()

    payload = {
        "email": email,
        "otp": otp_code,
        "username": "user248",
        "password": "somePassword123"
    }

    response = client.post(url, payload, format="json")

    assert response.status_code == 400
    data = response.json()
    assert "email" in data
    assert data["email"][0] == "Email is already taken."


@pytest.mark.django_db
def test_signup_already_username_registered():
    """
        # Create otp
        # Ensure no social user exists with this email
        # Ensure user and token created
        # Ensure user profile created
        # Repeat the steps above to create another user with same username
        # Ensure get response "username": ["Username is already taken."]
    """
    client = APIClient()
    url = reverse("users:signup")

    email = "user123@example.com"
    otp_code = "123456"
    
    hashed_otp = make_password(otp_code)

    SignupOneTimePasscode.objects.create(
        email=email,
        code=hashed_otp,
        expired_at=timezone.now() + timedelta(minutes=5)
    )

    assert not SocialNetwork.objects.filter(email=email).exists()

    payload = {
        "email": email,
        "otp": otp_code,
        "username": "user123",
        "password": "somePassword123"
    }

    response = client.post(url, payload, format="json")

    assert response.status_code == 201
    data = response.json()
    assert "token" in data
    assert data["user"]["email"] == email

    user = User.objects.get(email=email)
    assert Token.objects.filter(user=user).exists()

    profile = Profile.objects.get(user=user)
    assert profile is not None

    # Repeat
    email = "user248@example.com"

    SignupOneTimePasscode.objects.create(
        email=email,
        code=hashed_otp,
        expired_at=timezone.now() + timedelta(minutes=5)
    )

    assert not SocialNetwork.objects.filter(email=email).exists()

    payload = {
        "email": email,
        "otp": otp_code,
        "username": "user123",
        "password": "somePassword123"
    }

    response = client.post(url, payload, format="json")

    assert response.status_code == 400
    data = response.json()
    assert "username" in data
    assert data["username"][0] == "Username is already taken."


@pytest.mark.django_db
def test_signup_empty():
    """
        # Empty payload
        # Ensure get response "error": "Signup OTP not found or expired"
    """
    client = APIClient()
    url = reverse("users:signup")

    payload = {}

    response = client.post(url, payload, format="json")
    assert response.status_code == 404
    assert response.json() == {"error": "Signup OTP not found or expired"}


@pytest.mark.django_db
def test_signup_no_pasword():
    """
        # Missing password in payload
        # Ensure get response error {'password': ['This field is required.']}
    """
    client = APIClient()
    url = reverse("users:signup")

    email = "user123@example.com"
    otp_code = "123456"
    
    hashed_otp = make_password(otp_code)

    SignupOneTimePasscode.objects.create(
        email=email,
        code=hashed_otp,
        expired_at=timezone.now() + timedelta(minutes=5)
    )

    assert not SocialNetwork.objects.filter(email=email).exists()

    payload = {
        "email": email,
        "otp": otp_code,
        "username": "user123"
    }

    response = client.post(url, payload, format="json")

    assert response.status_code == 400
    data = response.json()
    assert "password" in data
    assert data["password"][0] == "This field is required."


@pytest.mark.django_db
def test_signup_no_username():
    """
        # Missing username in payload
        # Ensure get response error {'username': ['This field is required.']}
    """
    client = APIClient()
    url = reverse("users:signup")

    email = "user123@example.com"
    otp_code = "123456"
    
    hashed_otp = make_password(otp_code)

    SignupOneTimePasscode.objects.create(
        email=email,
        code=hashed_otp,
        expired_at=timezone.now() + timedelta(minutes=5)
    )

    assert not SocialNetwork.objects.filter(email=email).exists()

    payload = {
        "email": email,
        "otp": otp_code,
        "password": "stongPassword123"
    }

    response = client.post(url, payload, format="json")

    assert response.status_code == 400
    data = response.json()
    assert "username" in data
    assert data["username"][0] == "This field is required."


@pytest.mark.django_db
def test_signup_short_password():
    """
        # Input password of length less than 8
        # Ensure get response error {'password': ['Ensure this field has at least 8 characters.']}
    """
    client = APIClient()
    url = reverse("users:signup")

    email = "user123@example.com"
    otp_code = "123456"
    
    hashed_otp = make_password(otp_code)

    SignupOneTimePasscode.objects.create(
        email=email,
        code=hashed_otp,
        expired_at=timezone.now() + timedelta(minutes=5)
    )

    assert not SocialNetwork.objects.filter(email=email).exists()

    payload = {
        "email": email,
        "otp": otp_code,
        "password": "pas",
        "username": "user123"
    }

    response = client.post(url, payload, format="json")

    assert response.status_code == 400
    data = response.json()
    assert "password" in data
    assert data["password"][0] == "Ensure this field has at least 8 characters."


@pytest.mark.django_db
def test_signup_space_in_password():
    """
        # Input password with spaces
        # Ensure get response error {'password': ['The password must not contain spaces.']}
    """
    client = APIClient()
    url = reverse("users:signup")

    email = "user123@example.com"
    otp_code = "123456"
    
    hashed_otp = make_password(otp_code)

    SignupOneTimePasscode.objects.create(
        email=email,
        code=hashed_otp,
        expired_at=timezone.now() + timedelta(minutes=5)
    )

    assert not SocialNetwork.objects.filter(email=email).exists()

    payload = {
        "email": email,
        "otp": otp_code,
        "password": "strongPasword 123",
        "username": "user123"
    }

    response = client.post(url, payload, format="json")

    assert response.status_code == 400, response.json()
    data = response.json()
    assert "password" in data
    assert data["password"][0] == "The password must not contain spaces."