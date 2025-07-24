from rest_framework import serializers

class ErrorSerializer(serializers.Serializer):
    error = serializers.CharField()


#facebook_login
class FacebookLoginRequestSerializer(serializers.Serializer):
    fbAccessToken = serializers.CharField(help_text="Facebook access token")

class FacebookLoginUserSerializer(serializers.Serializer):
    id = serializers.IntegerField()
    username = serializers.CharField()

class FacebookLoginSuccessSerializer(serializers.Serializer):
    token = serializers.CharField()
    user = FacebookLoginUserSerializer()


#google_login
class GoogleLoginRequestSerializer(serializers.Serializer):
    idToken = serializers.CharField(required=False)
    socialId = serializers.CharField(required=False)
    socialEmail = serializers.EmailField(required=False)
    socialName = serializers.CharField(required=False)

class GoogleLoginUserSerializer(serializers.Serializer):
    id = serializers.IntegerField()
    username = serializers.CharField()

class GoogleLoginSuccessSerializer(serializers.Serializer):
    token = serializers.CharField()
    user = GoogleLoginUserSerializer()


#facebook_link
class FacebookLinkRequestSerializer(serializers.Serializer):
    fbAccessToken = serializers.CharField()

class FacebookLinkSuccessSerializer(serializers.Serializer):
    id = serializers.IntegerField()


#google_link
class GoogleLinkRequestSerializer(serializers.Serializer):
    idToken = serializers.CharField(required=False)
    socialId = serializers.CharField(required=False)
    socialEmail = serializers.EmailField(required=False)
    socialName = serializers.CharField(required=False)

class GoogleLinkSuccessSerializer(serializers.Serializer):
    id = serializers.IntegerField()
