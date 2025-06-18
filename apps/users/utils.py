import secrets
from .models import OneTimePasscode
from .models import SignupOneTimePasscode
from django.contrib.auth import get_user_model

User = get_user_model()


def create_otp_for_user(user):
    try:
        otp_code = secrets.randbelow(900000) + 100000

        OneTimePasscode.objects.filter(user=user).delete()

        otp = OneTimePasscode.objects.create(
            user=user,
            code=otp_code
        )
        return otp
    except Exception:
        return None

def create_otp_signup(email):
    try:
        otp_code = secrets.randbelow(900000) + 100000

        SignupOneTimePasscode.objects.filter(email=email).delete()

        otp = SignupOneTimePasscode.objects.create(
            email=email,
            code=otp_code
        )
        return otp
    except Exception:
        return None