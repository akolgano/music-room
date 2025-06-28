from django.contrib import admin

from .models import Playlist, PlaylistTrack
from apps.tracks.models import Track

class PlaylistTrackInline(admin.TabularInline):
    model = PlaylistTrack
    extra = 1
    ordering = ['position']
    readonly_fields = ['position']
    autocomplete_fields = ['track']
    fields = ['playlist', 'track', 'position', 'points']
    show_change_link = True

    def track_display(self, obj):
        return f"{obj.track.name} – {obj.track.artist}"
    track_display.short_description = "Track"

class PlaylistAdmin(admin.ModelAdmin):
    list_display = ['name', 'id', 'voted_users_display']
    inlines = [PlaylistTrackInline]

    def voted_users_display(self, obj):
        return ", ".join([user.username for user in obj.users_already_voted.all()])
    voted_users_display.short_description = "Users Voted"

class PlaylistTrackAdmin(admin.ModelAdmin):
    list_display = ['playlist', 'position', 'track_name', 'track_artist', 'points']
    ordering = ['playlist', 'position']
    list_filter = ['playlist']
    search_fields = ['track__name', 'track__artist']

    def track_name(self, obj):
        return obj.track.name

    def track_artist(self, obj):
        return obj.track.artist

    def track_points(self, obj):
        return obj.track.points
    
admin.site.register(Playlist, PlaylistAdmin)
admin.site.register(PlaylistTrack, PlaylistTrackAdmin)
