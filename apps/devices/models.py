from django.db import models
from django.contrib.auth import get_user_model

User = get_user_model()

class Device(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    uuid = models.CharField(max_length=255, unique=True)
    license_key = models.CharField(max_length=255, unique=True)
    is_active = models.BooleanField(default=True)

    def __str__(self):
        return f"{self.user.username}'s device ({self.uuid})"


class MusicControlDelegate(models.Model):
    owner = models.ForeignKey(User, on_delete=models.CASCADE, related_name="delegated_from")
    delegate = models.ForeignKey(User, on_delete=models.CASCADE, related_name="delegated_to")
    device = models.ForeignKey(Device, on_delete=models.CASCADE)
    can_control = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('owner', 'delegate', 'device')

