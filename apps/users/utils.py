import secrets
from django.utils import timezone
from .models import OneTimePasscode
from django.contrib.auth import get_user_model

User = get_user_model()


def generate_otp():
    otp_code = secrets.randbelow(900000) + 100000
    return otp_code


def create_otp_for_user(user):
    try:
        otp_code = generate_otp()

        OneTimePasscode.objects.filter(user=user).delete()

        otp = OneTimePasscode.objects.create(
            user=user,
            code=otp_code
        )
        return otp
    except Exception:
        return None


def get_otp_user(user):
    try:
        otp = OneTimePasscode.objects.get(user=user, expired_at__gt=timezone.now())
        return otp
    except OneTimePasscode.DoesNotExist:
        return None
    return None


def get_user(email):
    try:
        users = User.objects.filter(email=email)
        if users.count() == 1:
            user = users.first()
            return user
        else:
            return None
    except Exception:
        return None
