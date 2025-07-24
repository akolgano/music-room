from django.urls import path
from . import views

app_name = "auth"

urlpatterns = [
    path('facebook/login/', views.facebook_login, name='facebook_login'),
    path('google/login/', views.google_login, name='google_login'),
    path('facebook/link/', views.facebook_link, name='facebook_link'),
    path('google/link/', views.google_link, name='google_link'),
]
