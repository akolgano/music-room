from django.contrib import admin
from .models import Track

class TrackAdmin(admin.ModelAdmin):
    list_display = ['name', 'artist']
    search_fields = ['name', 'artist']

admin.site.register(Track, TrackAdmin)
