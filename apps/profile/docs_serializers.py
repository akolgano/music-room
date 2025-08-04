from rest_framework import serializers


class ErrorSerializer(serializers.Serializer):
    error = serializers.CharField()


class ErrorMultiSerializer(serializers.Serializer):
    detail = serializers.DictField(
        child=serializers.ListField(child=serializers.CharField())
    )


class DetailSerializer(serializers.Serializer):
    detail = serializers.CharField()
