from django.urls import path
from . import views

urlpatterns = [
    path('save_playlist/', views.save_shared_playlist, name='save_playlist'),
    path('saved_playlists/', views.get_user_saved_playlists, name='saved_playlists'),
    path('public_playlists/', views.get_all_shared_playlists, name='public_playlists'),
    path('to_playlist/<int:playlist_id>/add_track/<int:track_id>/', views.add_track_to_playlist, name='add_track_to_playlist'),
]
