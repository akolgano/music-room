from django.urls import path
from . import views


app_name = "playlists"


urlpatterns = [
    path('playlists', views.create_new_playlist, name='playlists'),
    path('playlists/<int:playlist_id>', views.get_playlist_info, name='get_playlist'),
    path('update_playlist/<int:playlist_id>', views.update_playlist, name='update_playlist'),
    path('delete_playlist/<int:playlist_id>', views.delete_playlist, name='delete_playlist'),
    path('playlists/<int:playlist_id>/remove_tracks', views.delete_track_from_playlist, name='remove_items'),
    path('saved_playlists/', views.get_user_saved_playlists, name='saved_playlists'),
    path('public_playlists/', views.get_all_shared_playlists, name='public_playlists'),
    path('playlist/<int:playlist_id>/tracks/', views.playlist_tracks, name='playlist_tracks'),
    path('<int:playlist_id>/add/', views.add_track, name='add_track'),
    path('<int:playlist_id>/move-track/', views.move_track_in_playlist, name='move_track_in_playlist'),
    path('<int:playlist_id>/change-visibility/', views.change_visibility, name='change_visibility'),
    path('<int:playlist_id>/invite-user/', views.invite_user, name='invite_user'),
    path('<int:playlist_id>/license/', views.patch_playlist_license, name='patch_playlist_license'),
    path('<int:playlist_id>/tracks/vote/', views.vote_for_track, name='vote_for_track'),

    # GET events
    path('saved_events/', views.get_user_saved_events, name='saved_events'),
    path('public_events/', views.get_all_shared_events, name='public_events'),
]
