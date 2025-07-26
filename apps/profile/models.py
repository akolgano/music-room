from django.db import models
from django.contrib.auth import get_user_model


User = get_user_model()


class VisibilityChoices(models.TextChoices):
    PUBLIC = 'public', 'Public'
    FRIENDS = 'friends', 'Friends only'
    PRIVATE = 'private', 'Private'


class MusicPreference(models.Model):
    name = models.CharField(max_length=100, unique=True)

    def __str__(self):
        return self.name


class Profile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='profile')
    
    avatar = models.ImageField(upload_to='avatars/', blank=True, null=True)
    avatar_visibility = models.CharField(max_length=10, choices=VisibilityChoices.choices, default=VisibilityChoices.PUBLIC)

    name = models.CharField(max_length=100, blank=True)
    name_visibility = models.CharField(max_length=10, choices=VisibilityChoices.choices, default=VisibilityChoices.PUBLIC)

    location = models.CharField(max_length=100, blank=True)
    location_visibility = models.CharField(max_length=10, choices=VisibilityChoices.choices, default=VisibilityChoices.PUBLIC)

    bio = models.TextField(blank=True)
    bio_visibility = models.CharField(max_length=10, choices=VisibilityChoices.choices, default=VisibilityChoices.PUBLIC)

    phone = models.CharField(max_length=20, blank=True)
    phone_visibility = models.CharField(max_length=10, choices=VisibilityChoices.choices, default=VisibilityChoices.PRIVATE)

    friend_info = models.TextField(blank=True)
    friend_info_visibility = models.CharField(max_length=10, choices=VisibilityChoices.choices, default=VisibilityChoices.FRIENDS)

    music_preferences = models.ManyToManyField(MusicPreference, blank=True)
    music_preferences_visibility = models.CharField(max_length=10, choices=VisibilityChoices.choices, default=VisibilityChoices.PUBLIC)

    def __str__(self):
        return f"{self.user.username}'s Profile"


