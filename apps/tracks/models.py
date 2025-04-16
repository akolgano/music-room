# ================================
# akolgano
# ================================

from django.db import models


class Track(models.Model):
    name = models.CharField(max_length=255)
    artist = models.CharField(max_length=255)
    deezer_track_id = models.CharField(max_length=255, unique=True, default=0)
    album = models.CharField(max_length=255, blank=True, null=True)
    url = models.URLField(default='')

    def __str__(self):
        return f"{self.name} by {self.artist}"
