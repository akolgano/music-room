from django.db import models
from django.contrib.auth import get_user_model
from apps.tracks.models import Track

User = get_user_model()


class Playlist(models.Model):

    creator = models.ForeignKey(User, on_delete=models.CASCADE, related_name="playlists")
    name = models.CharField(max_length=255)
    description = models.TextField()
    public = models.BooleanField(default=True)
    #tracks = models.ManyToManyField(Track, related_name='playlists')
    users_saved = models.ManyToManyField(User, related_name='saved_playlists', blank=True)

    def __str__(self):
        return self.name

class PlaylistTrack(models.Model):
    playlist = models.ForeignKey(Playlist, on_delete=models.CASCADE, related_name='tracks')
    track = models.ForeignKey(Track, on_delete=models.CASCADE)
    position = models.PositiveIntegerField()

    class Meta:
        unique_together = ('playlist', 'position')
        ordering = ['position']


    def save(self, *args, **kwargs):
        if not self.position:
            # Automatically set position to the next available integer
            self.position = PlaylistTrack.objects.filter(playlist=self.playlist).count()
        super().save(*args, **kwargs)
