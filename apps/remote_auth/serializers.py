from rest_framework import serializers
from django.contrib.auth import get_user_model
from django.contrib.auth.password_validation import validate_password
from django.core.exceptions import ValidationError
import re
User = get_user_model()


class NoStripCharField(serializers.CharField):
    def to_internal_value(self, data):
        return data


class RemoteUserSerializer(serializers.ModelSerializer):
    username = NoStripCharField(required=True, min_length=1, max_length=150)
    email = NoStripCharField(required=True)

    class Meta:
        model = User
        fields = ['id', 'username', 'email']

    def validate_username(self, value):
        if value != value.strip():
            raise serializers.ValidationError("Username cannot have leading or trailing spaces.")

        if not re.match(r'^\w+$', value):
            raise serializers.ValidationError("Username can only contain letters, numbers, and underscores.")

        if User.objects.filter(username=value).exists():
            raise serializers.ValidationError("Username is already taken.")

        return value

    def validate_email(self, value):
        if value != value.strip():
            raise serializers.ValidationError("Email cannot have leading or trailing spaces.")

        email_regex = r'^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$'
        if not re.match(email_regex, value):
            raise serializers.ValidationError("Enter a valid email address.")

        if User.objects.filter(email=value).exists():
            raise serializers.ValidationError("Email is already taken.")

        return value

    def create(self, validated_data):
        user = User.objects.create(**validated_data)
        user.set_unusable_password()
        user.save()
        return user

