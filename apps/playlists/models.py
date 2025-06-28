from django.db import models
from django.contrib.auth import get_user_model
from apps.tracks.models import Track

User = get_user_model()


class Playlist(models.Model):

    LICENSE_CHOICES = [
        ('open', 'Open to everyone'),
        ('invite_only', 'Invite only'),
        ('location_time', 'Time and location restricted'),
    ]

    creator = models.ForeignKey(User, on_delete=models.CASCADE, related_name="playlists")
    name = models.CharField(max_length=255)
    description = models.TextField()
    public = models.BooleanField(default=True)
    users_saved = models.ManyToManyField(User, related_name='saved_playlists', blank=True)
    users_already_voted = models.ManyToManyField(User, related_name='already_voted', blank=True)

    # License controls
    license_type = models.CharField(max_length=20, choices=LICENSE_CHOICES, default='open')
    invited_users = models.ManyToManyField(User, blank=True, related_name='invited_to_playlists')

    # Time-based voting
    vote_start_time = models.TimeField(blank=True, null=True)
    vote_end_time = models.TimeField(blank=True, null=True)

    # Location-based voting
    latitude = models.FloatField(blank=True, null=True)
    longitude = models.FloatField(blank=True, null=True)
    allowed_radius_meters = models.IntegerField(blank=True, null=True)

    def __str__(self):
        return self.name

class PlaylistTrack(models.Model):
    playlist = models.ForeignKey(Playlist, on_delete=models.CASCADE, related_name='tracks')
    track = models.ForeignKey(Track, on_delete=models.CASCADE)
    position = models.PositiveIntegerField()
    points = models.IntegerField(blank=True, null=True, default=0)

    class Meta:
        unique_together = ('playlist', 'position')
        ordering = ['position']


    def save(self, *args, **kwargs):
        if not self.position:
            # Automatically set position to the next available integer
            self.position = PlaylistTrack.objects.filter(playlist=self.playlist).count()
        super().save(*args, **kwargs)
