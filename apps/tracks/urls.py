from django.urls import path
from . import views

urlpatterns = [
    path('search/', views.search_tracks, name='search_tracks'),
    path('add_from_deezer/<int:track_id>/', views.add_track_from_deezer, name='add_track_from_deezer'),
]
