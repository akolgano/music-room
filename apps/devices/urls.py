from django.urls import path
from .views import register_device, delegate_control, check_control_permission

urlpatterns = [
    path('register/', register_device, name='device-register'),
    path('delegate/', delegate_control, name='delegate-control'),
    path('<str:device_uuid>/can-control/', check_control_permission, name='check-control-permission'),
]
