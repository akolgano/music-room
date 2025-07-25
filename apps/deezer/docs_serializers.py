from rest_framework import serializers

class ErrorSerializer(serializers.Serializer):
    error = serializers.CharField()


class DeezerContributorSerializer(serializers.Serializer):
    id = serializers.IntegerField()
    name = serializers.CharField()
    link = serializers.URLField()
    share = serializers.URLField()
    picture = serializers.URLField()
    picture_small = serializers.URLField()
    picture_medium = serializers.URLField()
    picture_big = serializers.URLField()
    picture_xl = serializers.URLField()
    radio = serializers.BooleanField()
    tracklist = serializers.URLField()
    type = serializers.CharField()
    role = serializers.CharField()


class DeezerArtistSerializer(serializers.Serializer):
    id = serializers.IntegerField()
    name = serializers.CharField()
    link = serializers.URLField()
    share = serializers.URLField()
    picture = serializers.URLField()
    picture_small = serializers.URLField()
    picture_medium = serializers.URLField()
    picture_big = serializers.URLField()
    picture_xl = serializers.URLField()
    radio = serializers.BooleanField()
    tracklist = serializers.URLField()
    type = serializers.CharField()


class DeezerAlbumSerializer(serializers.Serializer):
    id = serializers.IntegerField()
    title = serializers.CharField()
    link = serializers.URLField()
    cover = serializers.URLField()
    cover_small = serializers.URLField()
    cover_medium = serializers.URLField()
    cover_big = serializers.URLField()
    cover_xl = serializers.URLField()
    md5_image = serializers.CharField()
    release_date = serializers.DateField()
    tracklist = serializers.URLField()
    type = serializers.CharField()


class DeezerTrackSerializer(serializers.Serializer):
    id = serializers.IntegerField()
    readable = serializers.BooleanField()
    title = serializers.CharField()
    title_short = serializers.CharField()
    title_version = serializers.CharField(allow_blank=True)
    isrc = serializers.CharField()
    link = serializers.URLField()
    share = serializers.URLField()
    duration = serializers.IntegerField()
    track_position = serializers.IntegerField()
    disk_number = serializers.IntegerField()
    rank = serializers.IntegerField()
    release_date = serializers.DateField()
    explicit_lyrics = serializers.BooleanField()
    explicit_content_lyrics = serializers.IntegerField()
    explicit_content_cover = serializers.IntegerField()
    preview = serializers.URLField()
    bpm = serializers.FloatField()
    gain = serializers.FloatField()
    available_countries = serializers.ListField(child=serializers.CharField())
    contributors = DeezerContributorSerializer(many=True)
    md5_image = serializers.CharField()
    track_token = serializers.CharField()
    artist = DeezerArtistSerializer()
    album = DeezerAlbumSerializer()
    type = serializers.CharField()


class DeezerTrackSearchResponseSerializer(serializers.Serializer):
    data = DeezerTrackSerializer(many=True)
    total = serializers.IntegerField()
    next = serializers.URLField(allow_null=True)