from django.db import models
from django.contrib.auth.models import User
from django.contrib.postgres.fields import ArrayField


class Profile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='profile')
    
    avatar = models.CharField(
        max_length=100,
        null=True,
        blank=True,
        default=''
        )
    
    location = models.CharField(
        max_length=50,
        null=True,
        blank=True,
        default=''
        )
    
    bio = models.CharField(
        max_length=500,
        null=True,
        blank=True,
        default=''
        )

    name = models.CharField(
        max_length=100,
        null=True,
        blank=True,
        default=''
        )

    phone = models.CharField(
        max_length=10,
        null=True,
        blank=True,
        default=''
        )

    friend_info = models.CharField(
        max_length=500,
        null=True,
        blank=True,
        default=''
    )

    music_preferences = ArrayField(
        models.CharField(max_length=50),
        null=True,
        blank=True,
        default=list
    )

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "User Profile"
        verbose_name_plural = "User Profiles"
        
    def __str__(self):
        return (
            f"user id: {self.user.id}, avatar: {self.avatar},"
            f"location: {self.location}, bio: {self.bio},"
            f"name: {self.name},"
            f"phone: {self.phone},"    
            f"friend_info: {self.friend_info},"
            f"music_preferences: {self.music_preferences}"
        )
