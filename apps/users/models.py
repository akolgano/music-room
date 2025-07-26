import uuid
from django.db import models 
from django.conf import settings
from django.contrib.auth.models import AbstractUser
from django.utils import timezone
from datetime import timedelta


class CustomUser(AbstractUser):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)

class Friendship(models.Model):
    from_user = models.ForeignKey('users.CustomUser', related_name='friendships_created', on_delete=models.CASCADE)
    to_user = models.ForeignKey('users.CustomUser', related_name='friendships_received', on_delete=models.CASCADE)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    status = models.CharField(
        max_length=10,
        choices=[('pending', 'Pending'), ('accepted', 'Accepted')],
        default='pending'
    )
    class Meta:
        unique_together = ('from_user', 'to_user')
        verbose_name = 'Friendship'
        verbose_name_plural = 'Friendships'

    def __str__(self):
        return f"{self.from_user} -> {self.to_user}"


def get_expiry_time():
    return timezone.now() + timedelta(minutes=5)

class OneTimePasscode(models.Model):
    user = models.ForeignKey('users.CustomUser', on_delete=models.CASCADE)
    code = models.CharField(max_length=200)
    expired_at = models.DateTimeField(default=get_expiry_time)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"OTP code for {self.user.email} (expires at {self.expired_at})"

class SignupOneTimePasscode(models.Model):
    email = models.EmailField(unique=True)
    code = models.CharField(max_length=200)
    expired_at = models.DateTimeField(default=get_expiry_time)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"OTP code for {self.email} (expires at {self.expired_at})"
