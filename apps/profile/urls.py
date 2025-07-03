from django.urls import path
from . import views
from django.conf import settings

urlpatterns = [
    path('profile/update/', views.update_profile, name='update_profile'),
    path('profile/<int:user_id>/', views.get_user_profile, name='get_user_profile'),
]
