from rest_framework import serializers
from .models import Device, MusicControlDelegate
from django.contrib.auth import get_user_model

User = get_user_model()

class DeviceSerializer(serializers.ModelSerializer):
    class Meta:
        model = Device
        fields = ['id', 'user', 'uuid', 'license_key', 'is_active']
        read_only_fields = ['id', 'user', 'is_active']


class MusicControlDelegateSerializer(serializers.ModelSerializer):
    owner = serializers.StringRelatedField(read_only=True)
    delegate = serializers.SlugRelatedField(slug_field='username', queryset=User.objects.all())
    device = serializers.SlugRelatedField(slug_field='uuid', queryset=Device.objects.all())

    class Meta:
        model = MusicControlDelegate
        fields = ['id', 'owner', 'delegate', 'device', 'can_control', 'created_at']
        read_only_fields = ['id', 'owner', 'created_at']
