from django.urls import path
from . import views

urlpatterns = [
    path('playlists', views.create_new_playlist, name='playlists'),
    path('playlists/<int:playlist_id>', views.get_playlist_info, name='get_playlist'), 
    path('playlists/<int:playlist_id>/tracks', views.add_items_to_playlist, name='add_items'),
    path('playlists/<int:playlist_id>/remove_tracks', views.remove_playlist_items, name='remove_items'),
    #path('save_playlist/', views.save_shared_playlist, name='save_playlist'),
    path('saved_playlists/', views.get_user_saved_playlists, name='saved_playlists'),
    path('public_playlists/', views.get_all_shared_playlists, name='public_playlists'),
    path('playlist/<int:playlist_id>/tracks/', views.playlist_tracks),
    path('<int:playlist_id>/add/', views.add_track),
    path('move-track/', views.move_track_in_playlist),
]
