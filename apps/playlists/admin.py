from django.contrib import admin

from .models import Playlist, PlaylistTrack
from apps.tracks.models import Track

class PlaylistTrackInline(admin.TabularInline):
    model = PlaylistTrack
    extra = 1
    ordering = ['position']
    readonly_fields = ['position']
    autocomplete_fields = ['track']
    fields = ['playlist', 'track', 'position']
    show_change_link = True

    def track_display(self, obj):
        return f"{obj.track.name} – {obj.track.artist}"
    track_display.short_description = "Track"

class PlaylistAdmin(admin.ModelAdmin):
    list_display = ['name', 'id']
    inlines = [PlaylistTrackInline]

class PlaylistTrackAdmin(admin.ModelAdmin):
    list_display = ['playlist', 'position', 'track_name', 'track_artist']
    ordering = ['playlist', 'position']
    list_filter = ['playlist']
    search_fields = ['track__name', 'track__artist']

    def track_name(self, obj):
        return obj.track.name

    def track_artist(self, obj):
        return obj.track.artist

admin.site.register(Playlist, PlaylistAdmin)
admin.site.register(PlaylistTrack, PlaylistTrackAdmin)
