from django.urls import path
from . import views

urlpatterns = [
    path('facebook/login/', views.facebook_login, name='facebook_login'),
    path('google/login_web/', views.google_login_web, name='google_login_web'),
    path('google/login_app/', views.google_login_app, name='google_login_app'),
]
