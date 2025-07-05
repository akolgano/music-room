from rest_framework import serializers
from django.core.exceptions import ValidationError
from .models import Profile
from datetime import datetime


class ProfileSerializer(serializers.ModelSerializer):

    class Meta:
        model = Profile
        fields = [
            'id',
            'user',
            'avatar',
            'gender',
            'location',
            'bio',
            'first_name',
            'last_name',
            'phone',
            'street',
            'country',
            'postal_code',
            'dob',
            'hobbies',
            'friend_info',
            'music_preferences'
        ]
        read_only_fields = ['id']


    def validate_phone(self, value):
        if value and not value.isdigit():
            raise serializers.ValidationError("Phone number must contain only digits.")
        return value

    def validate_country(self, value):
        COUNTRIES = ['Singapore', 'Malaysia', 'Indonesia', 'Thailand', 'United States', 'Canada', 'United Kingdom', 'Australia']
        if value:
            if value not in COUNTRIES:
                raise serializers.ValidationError("Country must be 'Singapore', 'Malaysia', 'Indonesia', 'Thailand', 'United States', 'Canada', 'United Kingdom', 'Australia'.")
        return value

    def validate_postal_code(self, value):
        if value and not value.isdigit():
            raise serializers.ValidationError("Postal code must contain only digits.")
        return value

    def validate_dob(self, value):
        if value:
            if value >= datetime.today().date():
                raise serializers.ValidationError("Dob must be in the past.")
        return value

    def validate_hobbies(self, value):
        HOBBIES = ['Sport', 'Movie', 'Music', 'Travel']
        if value:
            if not isinstance(value, list):
                raise serializers.ValidationError("Hobbies must be a list.")
            for hobby in value:
                if not isinstance(hobby, str):
                    raise serializers.ValidationError("Each hobby must be a string.")
                if hobby not in HOBBIES:
                    raise serializers.ValidationError(f"{hobby} is not in hobbies list.")
                if value.count(hobby) > 1:
                    raise serializers.ValidationError("Each hobby must be unique.")
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
