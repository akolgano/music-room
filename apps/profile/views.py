from rest_framework.decorators import api_view, permission_classes, parser_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.authentication import TokenAuthentication
from rest_framework.parsers import MultiPartParser, FormParser
from rest_framework.response import Response
from rest_framework import status
from .serializers import ProfileSerializer, MusicPreferenceSerializer
from .utils import can_view_field
from django.shortcuts import get_object_or_404
from .models import Profile, MusicPreference
from rest_framework.decorators import api_view, authentication_classes

@api_view(['PUT', 'PATCH'])
@authentication_classes([TokenAuthentication])
@permission_classes([IsAuthenticated])
@parser_classes([MultiPartParser, FormParser])
def profile_update(request):
    profile = request.user.profile
    partial = request.method == 'PATCH'
    serializer = ProfileSerializer(profile, data=request.data, partial=partial, context={'request': request})
    if serializer.is_valid():
        serializer.save()
        return Response(serializer.data)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['GET'])
@authentication_classes([TokenAuthentication])
@permission_classes([IsAuthenticated])
def profile_detail(request, pk):
    profile = get_object_or_404(Profile, pk=pk)
    viewer = request.user
    is_self = viewer == profile.user

    data = {
        'id': profile.id,
        'user': profile.user.username,
    }

    fields = [
        ('avatar', profile.avatar_visibility),
        ('name', profile.name_visibility),
        ('location', profile.location_visibility),
        ('bio', profile.bio_visibility),
        ('phone', profile.phone_visibility),
        ('friend_info', profile.friend_info_visibility),
        ('music_preferences', profile.music_preferences_visibility),
    ]

    for field_name, visibility in fields:
        if is_self or can_view_field(viewer, profile.user, visibility):
            if field_name == 'music_preferences':
                prefs = profile.music_preferences.all().values_list('name', flat=True)
                data[field_name] = list(prefs)
            else:
                value = getattr(profile, field_name)
                if field_name == 'avatar' and value:
                    value = request.build_absolute_uri(value.url)
                data[field_name] = value

    return Response(data)


@api_view(['DELETE'])
@authentication_classes([TokenAuthentication])
@permission_classes([IsAuthenticated])
def delete_avatar(request):
    profile = request.user.profile
    if profile.avatar:
        profile.avatar.delete(save=True)
        return Response({'detail': 'Avatar deleted.'}, status=204)
    return Response({'detail': 'No avatar to delete.'}, status=400)


@api_view(['GET'])
@authentication_classes([TokenAuthentication])
@permission_classes([IsAuthenticated])
def music_preferences_list(request):
    preferences = MusicPreference.objects.all()
    serializer = MusicPreferenceSerializer(preferences, many=True)
    return Response(serializer.data)