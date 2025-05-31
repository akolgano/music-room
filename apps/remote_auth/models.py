from django.db import models
from django.conf import settings
from django.contrib.auth.models import User
from django.core.validators import EmailValidator


class SocialNetwork(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    type = models.CharField(
        max_length=8,
        choices=[('facebook', 'Facebook'), ('google', 'Google')]
        )
    
    social_id = models.CharField(
        max_length=32,
        unique=True,
        null=False,
        blank=False
        )
    
    name = models.CharField(
        max_length=150,
        blank=True,
        null=False,
        default=''
        )
    
    email = models.EmailField(
        max_length=255,
        blank=True,
        null=True,
        unique=True,
        validators=[EmailValidator()],
        error_messages={
            'error': 'This email address is already registered.'
        }
        )

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "Social Network Account"
        verbose_name_plural = "Social Network Accounts"
        unique_together = [('type', 'social_id')]

    def __str__(self):
        return (
            f"user id: {self.user.id}, username: {self.user.username}, user email: {self.user.email}," 
            f"social id: {self.social_id}, name: {self.name}, social email: {self.email}"
            )

