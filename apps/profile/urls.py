from django.urls import path
from . import views
from django.conf import settings

urlpatterns = [
    path('public/', views.public_info, name='public_info'),
    path('friend/', views.friend_info, name='friend_info'),
    path('private/', views.private_info, name='private_info'),
    path('music/', views.music_preferences, name='music_preferences'),
    path('public/update/', views.update_public_info, name='update_public_info'),
    path('friend/update/', views.update_friend_info, name='update_friend_info'),
    path('private/update/', views.update_private_info, name='update_private_info'),
    path('music/update/', views.update_music_preferences, name='update_music_pref'),

]