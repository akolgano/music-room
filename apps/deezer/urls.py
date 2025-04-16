from django.urls import path
from .views import get_deezer_track, search_deezer_tracks

urlpatterns = [
    path('track/<str:track_id>/', get_deezer_track, name='get_deezer_track'),
    path('search/', search_deezer_tracks, name='search_deezer_tracks'),
]
