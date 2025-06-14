import os
from rest_framework.decorators import api_view, authentication_classes, permission_classes
from django.http import JsonResponse
from rest_framework import status
from django.contrib.auth import get_user_model
import requests
from rest_framework.response import Response
from rest_framework.authtoken.models import Token
from .models import ProfilePublic
from .models import ProfilePrivate
from .models import ProfileFriend
from .models import ProfileMusic
from rest_framework.authentication import TokenAuthentication
from rest_framework.permissions import IsAuthenticated
from django.conf import settings
import base64
import uuid
from urllib.parse import urljoin


User = get_user_model()


@api_view(['POST'])
@authentication_classes([TokenAuthentication])
@permission_classes([IsAuthenticated])
def update_public_info(request):
    user = request.user
    avatar_base64 = request.data.get('avatarBase64')
    mime_type = request.data.get('mimeType')
    gender = request.data.get('gender')
    location = request.data.get('location')
    bio = request.data.get('bio')
    
    try:
        profile_public = ProfilePublic.objects.filter(user=user).first()
        if not profile_public:
            profile_public = ProfilePublic.objects.create(
                user = user,
            )
        if mime_type and avatar_base64:
            ext = '.' + mime_type.split('/')[1]
            filename = uuid.uuid4().hex + ext
            file_data = base64.b64decode(avatar_base64)
            save_dir = os.path.join(settings.MEDIA_ROOT)
            file_path = os.path.join(save_dir, filename)
            with open(file_path, 'wb') as f:
                f.write(file_data)
            media_url = urljoin(settings.MEDIA_URL, filename)
            if file_path:
                profile_public.avatar = media_url

        if gender:
            profile_public.gender = gender
        
        if location:
            profile_public.location = location
        
        if bio:
            profile_public.bio = bio
        
        profile_public.save()

        data = {
            'avatar': profile_public.avatar,
            'gender': profile_public.gender,
            'location': profile_public.location,
            'bio': profile_public.bio,
        }
        return JsonResponse(data, status=status.HTTP_200_OK)
        
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)


@api_view(['GET'])
@authentication_classes([TokenAuthentication])
@permission_classes([IsAuthenticated])
def public_info(request):
    user = request.user
    try:
        profile_public = ProfilePublic.objects.filter(user=user).first()
        if not profile_public:
            profile_public = ProfilePublic.objects.create(
                user = user,
            )
        data = {
            'avatar': profile_public.avatar,
            'gender': profile_public.gender,
            'location': profile_public.location,
            'bio': profile_public.bio,   
        }
        return JsonResponse(data, status=status.HTTP_200_OK)
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)


@api_view(['POST'])
@authentication_classes([TokenAuthentication])
@permission_classes([IsAuthenticated])
def update_private_info(request):
    user = request.user
    first_name = request.data.get('firstName')
    last_name = request.data.get('lastName')
    phone = request.data.get('phone')
    street = request.data.get('street')
    country = request.data.get('country')
    postal_code = request.data.get('postalCode')
    
    try:
        profile_private = ProfilePrivate.objects.filter(user=user).first()
        if not profile_private:
            profile_private = ProfilePrivate.objects.create(
                user = user,
            )
    
        if first_name:
            profile_private.first_name = first_name
        
        if last_name:
            profile_private.last_name = last_name

        if phone:
            profile_private.phone = phone
        
        if street:
            profile_private.street = street
        
        if country:
            profile_private.country = country
        
        if postal_code:
            profile_private.postal_code = postal_code
        
        profile_private.save()

        data = {
            'first_name': profile_private.first_name,
            'last_name': profile_private.last_name,
            'phone': profile_private.phone,
            'street': profile_private.street,
            'country': profile_private.country,
            'postal_code': profile_private.postal_code
        }
        return JsonResponse(data, status=status.HTTP_200_OK)
        
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)


@api_view(['GET'])
@authentication_classes([TokenAuthentication])
@permission_classes([IsAuthenticated])
def private_info(request):
    user = request.user
    try:
        profile_private = ProfilePrivate.objects.filter(user=user).first()
        if not profile_private:
            profile_private = ProfilePrivate.objects.create(
                user = user,
            )
        data = {
            'first_name': profile_private.first_name,
            'last_name': profile_private.last_name,
            'phone': profile_private.phone,
            'street': profile_private.street,
            'country': profile_private.country,
            'postal_code': profile_private.postal_code
        }
        return JsonResponse(data, status=status.HTTP_200_OK)
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)


@api_view(['POST'])
@authentication_classes([TokenAuthentication])
@permission_classes([IsAuthenticated])
def update_friend_info(request):
    user = request.user
    dob = request.data.get('dob')
    hobbies = request.data.get('hobbies', [])
    friend_info = request.data.get('friendInfo')
    
    try:
        profile_friend = ProfileFriend.objects.filter(user=user).first()
        if not profile_friend:
            profile_friend = ProfileFriend.objects.create(
                user = user,
            )
    
        if dob:
            profile_friend.dob = dob
        
        if hobbies:
            profile_friend.hobbies = hobbies

        if friend_info:
            profile_friend.friend_info = friend_info
        
        profile_friend.save()

        data = {
            'dob': profile_friend.dob,
            'hobbies': profile_friend.hobbies,
            'friend_info': profile_friend.friend_info
        }
        return JsonResponse(data, status=status.HTTP_200_OK)
        
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)


@api_view(['GET'])
@authentication_classes([TokenAuthentication])
@permission_classes([IsAuthenticated])
def friend_info(request):
    user = request.user
    try:
        profile_friend = ProfileFriend.objects.filter(user=user).first()
        if not profile_friend:
            profile_friend = ProfileFriend.objects.create(
                user = user,
            )
        data = {
            'dob': profile_friend.dob,
            'hobbies': profile_friend.hobbies,
            'friend_info': profile_friend.friend_info
        }
        return JsonResponse(data, status=status.HTTP_200_OK)
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)


@api_view(['POST'])
@authentication_classes([TokenAuthentication])
@permission_classes([IsAuthenticated])
def update_music_preferences(request):
    user = request.user
    music_preferences = request.data.get('musicPreferences', [])
    
    try:
        profile_music = ProfileMusic.objects.filter(user=user).first()
        if not profile_music:
            profile_music = ProfileMusic.objects.create(
                user = user,
            )
        
        if music_preferences:
            profile_music.music_preferences = music_preferences
        
        profile_music.save()

        data = {
            'music_preferences': profile_music.music_preferences,
        }
        return JsonResponse(data, status=status.HTTP_200_OK)
        
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)


@api_view(['GET'])
@authentication_classes([TokenAuthentication])
@permission_classes([IsAuthenticated])
def music_preferences(request):
    user = request.user
    try:
        profile_music = ProfileMusic.objects.filter(user=user).first()
        if not profile_music:
            profile_music = ProfileMusic.objects.create(
                user = user,
            )
        data = {
            'music_preferences': profile_music.music_preferences,
        }
        return JsonResponse(data, status=status.HTTP_200_OK)
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)