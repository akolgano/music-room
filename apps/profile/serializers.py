from rest_framework import serializers
from django.core.exceptions import ValidationError
from .models import Profile
from datetime import datetime
from django.contrib.postgres.fields import ArrayField


class ProfileSerializer(serializers.ModelSerializer):

    class Meta:
        model = Profile
        fields = [
            'id',
            'user',
            'avatar',
            'location',
            'bio',
            'name',
            'phone',
            'friend_info',
            'music_preferences'
        ]
        read_only_fields = ['id']

    def validate_phone(self, value):
        if value and not value.isdigit():
            raise serializers.ValidationError("Phone number must contain only digits.")
        return value

    def validate_music_preferences(self, value):
        MUSIC_PREFERENCES = ['Classical', 'Jazz', 'Pop', 'Rock', 'Rap', 'R&B', 'Techno']
        if value:
            if not isinstance(value, list):
                raise serializers.ValidationError("Music preferences must be a list.")
            for pref in value:
                if not isinstance(pref, str):
                    raise serializers.ValidationError("Each music preference must be a string.")
                if pref not in MUSIC_PREFERENCES:
                    raise serializers.ValidationError(f"{pref} is not in music preferences list.")
                if value.count(pref) > 1:
                    raise serializers.ValidationError("Each music preference must be unique.")
        return value
    

class FriendInfoSerializer(serializers.ModelSerializer):

    class Meta:
        model = Profile
        fields = [
            'id',
            'user',
            'avatar',
            'location',
            'bio',
            'friend_info'
        ]
        read_only_fields = ['id']


class PublicInfoSerializer(serializers.ModelSerializer):

    class Meta:
        model = Profile
        fields = [
            'id',
            'user',
            'avatar',
            'location',
            'bio'
        ]
        read_only_fields = ['id']
