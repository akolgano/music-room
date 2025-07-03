import os
from rest_framework.decorators import api_view, authentication_classes, permission_classes
from django.http import JsonResponse
from rest_framework import status
from django.contrib.auth import get_user_model
import requests
from rest_framework.response import Response
from rest_framework.authtoken.models import Token
from rest_framework.authentication import TokenAuthentication
from rest_framework.permissions import IsAuthenticated
from django.conf import settings
import base64
import uuid
from urllib.parse import urljoin
from .models import Profile
from rest_framework import serializers
from .serializers import ProfileSerializer, FriendInfoSerializer, PublicInfoSerializer
from django.core.exceptions import ValidationError
from drf_yasg.utils import swagger_auto_schema
from drf_yasg import openapi
from PIL import Image
import io
from apps.users.models import Friendship
from django.db.models import Q


MAX_FILE_SIZE_MB = 1
MAX_FILE_SIZE_BYTES = MAX_FILE_SIZE_MB * 1024 * 1024

User = get_user_model()


@swagger_auto_schema(
    method='patch',
    operation_summary="Update user profile",
    request_body=openapi.Schema(
        type=openapi.TYPE_OBJECT,
        properties={
            'avatar_base64': openapi.Schema(type=openapi.TYPE_STRING, description="Base64 encoded avatar image"),
            'mime_type': openapi.Schema(type=openapi.TYPE_STRING, description="MIME type of the image ('image/jpeg' or 'image/png')"),
            'location': openapi.Schema(type=openapi.TYPE_STRING),
            'bio': openapi.Schema(type=openapi.TYPE_STRING),
            'name': openapi.Schema(type=openapi.TYPE_STRING),
            'phone': openapi.Schema(type=openapi.TYPE_STRING),
            'friend_info': openapi.Schema(type=openapi.TYPE_STRING),
            'music_preferences': openapi.Schema(type=openapi.TYPE_ARRAY, items=openapi.Items(type=openapi.TYPE_STRING)),
        }
    ),
    responses={
        200: openapi.Response(
            description="Profile updated successfully",
            schema=ProfileSerializer()
            ),
        401: openapi.Response(
            description="Unauthorized",
            schema=openapi.Schema(
                type=openapi.TYPE_OBJECT,
                properties={'detail': openapi.Schema(type=openapi.TYPE_STRING)},
                example={'detail': 'Authentication credentials were not provided'}
            )
        ),
        400: openapi.Response(
            description="Update user profile failed due to error",
            schema=openapi.Schema(
                type=openapi.TYPE_OBJECT,
                properties={
                    "error": openapi.Schema(type=openapi.TYPE_STRING),
                },
                additional_properties=openapi.Schema(
                    type=openapi.TYPE_ARRAY,
                    items=openapi.Schema(type=openapi.TYPE_STRING)
                ),
                example={
                    "phone": ["Phone number must contain only digits"],
                    "music_preferences": ["xxxx is not in music preferences list"],
                    "music_preferences": ["Each music preference must be unique"],
                    "error": "avatar_base64 is not valid image | mime_type not image/png or image/jpeg",
                    "error": "avatar file size exceeds 1 MB limit",
                    "error": "mime_type not image/png or image/jpeg"
                }
            ),
        )
    }
)
@api_view(['PATCH'])
@authentication_classes([TokenAuthentication])
@permission_classes([IsAuthenticated])
def update_profile(request):
    user = request.user
    avatar_base64 = request.data.get('avatar_base64')
    mime_type = request.data.get('mime_type')

    avatar = ''
    data = request.data.copy()
    data['user'] = user.id

    try:
        if mime_type and avatar_base64:
            if mime_type not in ['image/png', 'image/jpeg']:
                return JsonResponse({'error': 'mime_type not image/png or image/jpeg'}, status=status.HTTP_400_BAD_REQUEST)
            if not is_valid_image_base64(avatar_base64, mime_type):
                return JsonResponse({'error': 'avatar_base64 is not valid image'}, status=status.HTTP_400_BAD_REQUEST)
            ext = '.' + mime_type.split('/')[1]
            filename = uuid.uuid4().hex + ext
            file_data = base64.b64decode(avatar_base64)
            if len(file_data) > MAX_FILE_SIZE_BYTES:
                return JsonResponse({'error': f'avatar file size exceeds {MAX_FILE_SIZE_MB} MB limit'}, status=status.HTTP_400_BAD_REQUEST)
            save_dir = os.path.join(settings.MEDIA_ROOT)
            file_path = os.path.join(save_dir, filename)
            with open(file_path, 'wb') as f:
                f.write(file_data)
            media_url = urljoin(settings.MEDIA_URL, filename)
            if file_path:
                avatar = media_url
            if avatar:
                data['avatar'] = avatar
    except Exception as e:
        return JsonResponse({'error': '(avatar)'+str(e)}, status=status.HTTP_400_BAD_REQUEST)

    profile = Profile.objects.get(user=user)
    serializer = ProfileSerializer(profile, data=data, partial=True)
    if serializer.is_valid():
        profile = serializer.save()
        return JsonResponse(serializer.data, status=status.HTTP_200_OK)
    return JsonResponse(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@swagger_auto_schema(
    method='get',
    operation_summary="Get user profile",
    manual_parameters=[
        openapi.Parameter(
            'user_id',
            openapi.IN_PATH,
            description="Get user profile",
            type=openapi.TYPE_INTEGER,
            required=True,
        )
    ],
    responses={
        200: openapi.Response(
            description="User profile get successful",
            schema=ProfileSerializer()
        ),
        400: openapi.Response(
            description="User profile get failed due to error ",
            schema=openapi.Schema(
                type=openapi.TYPE_OBJECT,
                properties={'error': openapi.Schema(type=openapi.TYPE_STRING)},
            )
        ),
        401: openapi.Response(
            description="Unauthorized",
            schema=openapi.Schema(
                type=openapi.TYPE_OBJECT,
                properties={'detail': openapi.Schema(type=openapi.TYPE_STRING)},
                example={'detail': 'Authentication credentials were not provided'}
            )
        ),
    }
)
@api_view(['GET'])
@authentication_classes([TokenAuthentication])
@permission_classes([IsAuthenticated])
def get_user_profile(request, user_id):
    user = request.user
    try:
        if user.id == user_id:
            profile = Profile.objects.filter(user=user).first()
            serializer = ProfileSerializer(profile)
            return JsonResponse(serializer.data, status=status.HTTP_200_OK)

        profile = Profile.objects.filter(user_id=user_id).first()
        if not profile:
            return JsonResponse({'error': "No such profile"}, status=status.HTTP_400_BAD_REQUEST)

        is_friend = is_a_friend(user, user_id)
        if is_friend:
            serializer = FriendInfoSerializer(profile)
            return JsonResponse(serializer.data, status=status.HTTP_200_OK)
        else:
            serializer = PublicInfoSerializer(profile)
            return JsonResponse(serializer.data, status=status.HTTP_200_OK)
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)


def is_valid_image_base64(img_base64, mime_type):

    mime_to_format = {
        'image/png': 'PNG',
        'image/jpeg': 'JPEG'
    }

    try:
        image_data = base64.b64decode(img_base64)
        image = Image.open(io.BytesIO(image_data))
        image.load()
        expected_format = mime_to_format.get(mime_type)
        return image.format == expected_format
    except Exception as e:
        return False


def is_a_friend(user, friend_id):
    friends = Friendship.objects.filter(
        Q(from_user=user) | Q(to_user=user),
        status='accepted')

    for friend in friends:
        if (friend.from_user_id == friend_id):
            return True
        if (friend.to_user_id == friend_id):
            return True
    
    return False