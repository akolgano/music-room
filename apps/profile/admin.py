from django.contrib import admin
from django.utils.html import format_html
from .models import Profile, MusicPreference

@admin.register(Profile)
class ProfileAdmin(admin.ModelAdmin):
    list_display = ('user', 'name', 'location', 'phone', 'avatar_preview')
    search_fields = ('user__username', 'name', 'location')
    filter_horizontal = ('music_preferences',)
    readonly_fields = ('avatar_preview',)

    def avatar_preview(self, obj):
        if obj.avatar:
            return format_html(
                '<img src="{}" style="height: 60px; width: 60px; border-radius: 50%; object-fit: cover;" />',
                obj.avatar.url
            )
        return "No avatar"

    avatar_preview.short_description = 'Avatar'

@admin.register(MusicPreference)
class MusicPreferenceAdmin(admin.ModelAdmin):
    search_fields = ('name',)