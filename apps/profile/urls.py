from django.urls import path
from .views import profile_detail, profile_update, delete_avatar,music_preferences_list

urlpatterns = [
    #path('', profile_list, name='profile-list'), #to do later ?
    path('<uuid:pk>/', profile_detail, name='profile-detail'),
    path('me/', profile_update, name='profile-update'),
    path('me/avatar/', delete_avatar, name='delete-avatar'),
    path('music-preferences/', music_preferences_list, name='music-preferences-list'),
]