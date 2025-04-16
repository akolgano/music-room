from django.db import models
from django.contrib.auth import get_user_model
from apps.tracks.models import Track

User = get_user_model()


class Playlist(models.Model):

    creator = models.ForeignKey(User, on_delete=models.CASCADE, related_name="playlists")
    name = models.CharField(max_length=255)
    description = models.TextField()
    public = models.BooleanField(default=True)
    tracks = models.ManyToManyField(Track, related_name='playlists')
    users_saved = models.ManyToManyField(User, related_name='saved_playlists', blank=True)

    def __str__(self):
        return self.name
