from django.urls import path
from . import views

app_name = "users"

urlpatterns = [
    path('signup/', views.signup, name='signup'),
    path('login/', views.login_view, name='login'),
    path('logout/', views.logout_view, name='logout'),
    path('get_friends/', views.get_friends_list, name='get_friends'),
    path('send_friend_request/<int:user_id>/', views.send_friend_request, name='send_friend_request'),
    path('accept_friend_request/<int:friendship_id>/', views.accept_friend_request, name='accept_friend_request'),
    path('reject_friend_request/<int:friendship_id>/', views.reject_friend_request, name='reject_friend_request'),
    path('remove_friend/<int:user_id>/', views.remove_friend, name='remove_friend'),
]

