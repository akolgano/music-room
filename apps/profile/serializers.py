from rest_framework import serializers
from .models import Profile, MusicPreference

class MusicPreferenceSerializer(serializers.ModelSerializer):
    class Meta:
        model = MusicPreference
        fields = ['id', 'name']

class ProfileSerializer(serializers.ModelSerializer):

    music_preferences = serializers.SerializerMethodField()

    music_preferences_ids = serializers.PrimaryKeyRelatedField(
        many=True, queryset=MusicPreference.objects.all(), write_only=True, required=False
    )

    class Meta:
        model = Profile
        fields = [
            'avatar', 'name', 'location', 'bio', 'phone', 'friend_info',
            'avatar_visibility', 'name_visibility', 'location_visibility',
            'bio_visibility', 'phone_visibility', 'friend_info_visibility',
            'music_preferences_visibility', 'music_preferences', 'music_preferences_ids',
        ]

    def get_music_preferences(self, obj):
        return list(obj.music_preferences.values_list('name', flat=True))

    def update(self, instance, validated_data):
        music_prefs = validated_data.pop('music_preferences_ids', None)
        if music_prefs is not None:
            instance.music_preferences.set(music_prefs)

        return super().update(instance, validated_data)


class MusicPreferenceSerializer(serializers.ModelSerializer):
    class Meta:
        model = MusicPreference
        fields = ['id', 'name']