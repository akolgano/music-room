# from django.contrib.auth.models import AbstractUser

# class CustomUser(AbstractUser):
#     pass

from django.db import models 
from django.conf import settings
from django.contrib.auth.models import User
from django.contrib.auth.models import AbstractUser

class Friendship(models.Model):
    from_user = models.ForeignKey(User, related_name='friendships_created', on_delete=models.CASCADE)
    to_user = models.ForeignKey(User, related_name='friendships_received', on_delete=models.CASCADE)

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
