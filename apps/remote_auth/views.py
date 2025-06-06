import os
from rest_framework.decorators import api_view, authentication_classes, permission_classes
from django.http import JsonResponse
from rest_framework.decorators import api_view
from rest_framework import status
from django.contrib.auth import get_user_model
import requests
from rest_framework.response import Response
from rest_framework.authtoken.models import Token
from apps.users.serializers import UserSerializer
from django.shortcuts import get_object_or_404
from django.http import Http404
from django.utils import timezone
from google.oauth2 import id_token as google_id_token
from google.auth.transport import requests as google_requests
from .models import SocialNetwork
from .serializers import RemoteUserSerializer
from rest_framework.authentication import TokenAuthentication
from rest_framework.permissions import IsAuthenticated

User = get_user_model()

FACEBOOK_APP_ID = os.environ.get('FACEBOOK_APP_ID')
FACEBOOK_APP_SECRET = os.environ.get('FACEBOOK_APP_SECRET')
GOOGLE_CLIENT_ID_WEB = os.environ.get('GOOGLE_CLIENT_ID_WEB')
GOOGLE_CLIENT_ID_APP = os.environ.get('GOOGLE_CLIENT_ID_APP')


@api_view(['POST'])
def facebook_login(request):

    fb_access_token = request.data.get('fbAccessToken')

    if not fb_access_token:
        return JsonResponse({'error': 'Access token not provided'}, status=status.HTTP_400_BAD_REQUEST)

    verify_access_token_url = f'https://graph.facebook.com/debug_token?input_token={fb_access_token}&access_token={FACEBOOK_APP_ID}|{FACEBOOK_APP_SECRET}'
    veriify_response = requests.get(verify_access_token_url).json()

    if not veriify_response.get('data', {}).get('is_valid'):
        return JsonResponse({'error': 'Invalid Facebook access token'}, status=status.HTTP_400_BAD_REQUEST)

    user_id = veriify_response['data']['user_id']

    user_info_url = f'https://graph.facebook.com/{user_id}?fields=id,name,email&access_token={fb_access_token}'
    user_info = requests.get(user_info_url).json()

    email = user_info.get('email')
    username = user_info.get('name') or email.split('@')[0]
    username = username.replace(' ', '_')
    social_id = user_info.get('id');

    if not email:
        return JsonResponse({'error': 'Invalid login credentials'}, status=status.HTTP_400_BAD_REQUEST)
    
    return social_login(email, username, social_id, 'facebook')


@api_view(['POST'])
def google_login(request):
    id_token = request.data.get('idToken')
    type = request.data.get('type')
    
    if not id_token:
        return JsonResponse({'error': 'idToken token not provided'}, status=status.HTTP_400_BAD_REQUEST)
    if not type:
        return JsonResponse({'error': 'type not provided'}, status=status.HTTP_400_BAD_REQUEST)

    if type == 'web':
        google_client_id = GOOGLE_CLIENT_ID_WEB
    if type == 'app':
        google_client_id = GOOGLE_CLIENT_ID_APP
    
    try:
        id_info = google_id_token.verify_oauth2_token(id_token, google_requests.Request(), google_client_id)
    except ValueError:
        return JsonResponse({'error': 'Invalid idToken'}, status=status.HTTP_400_BAD_REQUEST)

    email = id_info.get('email')
    username = id_info.get('name') or id_info.get('email').split('@')[0]
    username = username.replace(' ', '_')
    social_id = id_info.get('sub')

    if not email:
            return JsonResponse({'error': 'Invalid login credentials'}, status=status.HTTP_400_BAD_REQUEST)

    return social_login(email, username, social_id, 'google')


def social_login(email, username, social_id, type):

    user_data = {
        'username': username,
        'email': email
    }

    social = SocialNetwork.objects.filter(social_id=social_id).first()

    if not social:
        user = User.objects.filter(email=email).first()
        if not user:
            serializer = RemoteUserSerializer(data=user_data)
            if serializer.is_valid():
                user = serializer.save()
                token = Token.objects.create(user=user)
                response_data = {
                    'token': token.key,
                    'user': serializer.data
                }
                SocialNetwork.objects.create(
                    user = user,
                    type = type,
                    social_id = social_id,
                    name = username,
                    email = email
                )
                return JsonResponse(response_data, status=status.HTTP_200_OK)
        else:
            return JsonResponse({'error': 'Already has a account with same email.'}, status=status.HTTP_400_BAD_REQUEST)
    
    if social:
        user = social.user
        token, created = Token.objects.get_or_create(user=user)
        user.last_activity = timezone.now()
        user.save()
        response_data = {
            'token': token.key,
            'user': {
                'username': user.username,
                'id': user.id
            }
        }
        return JsonResponse(response_data, status=status.HTTP_200_OK)     


@api_view(['POST'])
@authentication_classes([TokenAuthentication])
@permission_classes([IsAuthenticated])
def facebook_link(request):

    fb_access_token = request.data.get('fbAccessToken')
    user = request.user

    if not fb_access_token:
        return JsonResponse({'error': 'Access token not provided'}, status=status.HTTP_400_BAD_REQUEST)

    verify_access_token_url = f'https://graph.facebook.com/debug_token?input_token={fb_access_token}&access_token={FACEBOOK_APP_ID}|{FACEBOOK_APP_SECRET}'
    veriify_response = requests.get(verify_access_token_url).json()

    if not veriify_response.get('data', {}).get('is_valid'):
        return JsonResponse({'error': 'Invalid Facebook access token'}, status=status.HTTP_400_BAD_REQUEST)

    user_id = veriify_response['data']['user_id']

    user_info_url = f'https://graph.facebook.com/{user_id}?fields=id,name,email&access_token={fb_access_token}'
    user_info = requests.get(user_info_url).json()

    email = user_info.get('email')
    username = user_info.get('name') or email.split('@')[0]
    username = username.replace(' ', '_')
    social_id = user_info.get('id');

    if not email:
        return JsonResponse({'error': 'Invalid login credentials'}, status=status.HTTP_400_BAD_REQUEST)

    return social_link(user, email, username, social_id, 'facebook')


@api_view(['POST'])
@authentication_classes([TokenAuthentication])
@permission_classes([IsAuthenticated])
def google_link(request):
    id_token = request.data.get('idToken')
    type = request.data.get('type')
    user = request.user

    if not id_token:
        return JsonResponse({'error': 'idToken token not provided'}, status=status.HTTP_400_BAD_REQUEST)

    if type == 'web':
        google_client_id = GOOGLE_CLIENT_ID_WEB
    if type == 'app':
        google_client_id = GOOGLE_CLIENT_ID_APP

    try:
        id_info = google_id_token.verify_oauth2_token(id_token, google_requests.Request(), google_client_id)
    except ValueError:
        return JsonResponse({'error': 'Invalid idToken'}, status=status.HTTP_400_BAD_REQUEST)

    email = id_info.get('email')
    username = id_info.get('name') or id_info.get('email').split('@')[0]
    username = username.replace(' ', '_')
    social_id = id_info.get('sub')

    if not email:
            return JsonResponse({'error': 'Invalid login credentials'}, status=status.HTTP_400_BAD_REQUEST)

    return social_link(user, email, username, social_id, 'google')


def social_link(user, email, username, social_id, type):

    user_email = User.objects.filter(email=email).first()
    if user_email:
        if user_email.id != user.id:
            return JsonResponse({'error': 'Email use by other user'}, status=status.HTTP_400_BAD_REQUEST)

    social = SocialNetwork.objects.filter(user=user).first()
    if not social:
        social_email = SocialNetwork.objects.filter(email=email).first()
        social_social_id = SocialNetwork.objects.filter(social_id=social_id).first()
        if not social_email and not social_social_id:
            SocialNetwork.objects.create(
                user = user,
                type = type,
                social_id = social_id,
                name = username,
                email = email
            )
            return JsonResponse({'id': user.id}, status=status.HTTP_200_OK)
        else:
            return JsonResponse({'error': 'Email or Social network already in use'}, status=status.HTTP_400_BAD_REQUEST)
    else:
        return JsonResponse({'error': 'Social network already linked'}, status=status.HTTP_400_BAD_REQUEST)