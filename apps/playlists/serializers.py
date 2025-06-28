from rest_framework import serializers
from .models import Playlist
from django.contrib.auth.models import User

class PlaylistLicenseSerializer(serializers.ModelSerializer):
    invited_users = serializers.PrimaryKeyRelatedField(
        queryset=User.objects.all(), many=True, required=False
    )

    class Meta:
        model = Playlist
        fields = [
            'license_type',
            'invited_users',
            'vote_start_time',
            'vote_end_time',
            'latitude',
            'longitude',
            'allowed_radius_meters',
        ]


class VoteSerializer(serializers.Serializer):
    range_start = serializers.IntegerField()