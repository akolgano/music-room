import os
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
from google.oauth2 import id_token
from google.auth.transport import requests as google_requests

User = get_user_model()

FACEBOOK_APP_ID = os.environ.get('FACEBOOK_APP_ID')
FACEBOOK_APP_SECRET = os.environ.get('FACEBOOK_APP_SECRET')
REMOTE_USER_PASSWORD = os.environ.get('REMOTE_USER_PASSWORD')
GOOGLE_CLIENT_ID_WEB = os.environ.get('GOOGLE_CLIENT_ID_WEB')
GOOGLE_CLIENT_ID_APP = os.environ.get('GOOGLE_CLIENT_ID_APP')


@api_view(['POST'])
def facebook_login(request):

    fbAccessToken = request.data.get('fbAccessToken')

    if not fbAccessToken:
        return JsonResponse({'error': 'Access token not provided'}, status=status.HTTP_400_BAD_REQUEST)

    verifyAccessTokenUrl = f"https://graph.facebook.com/debug_token?input_token={fbAccessToken}&access_token={FACEBOOK_APP_ID}|{FACEBOOK_APP_SECRET}"
    veriifyResponse = requests.get(verifyAccessTokenUrl).json()

    if not veriifyResponse.get('data', {}).get('is_valid'):
        return JsonResponse({'error': 'Invalid Facebook access token'}, status=status.HTTP_400_BAD_REQUEST)

    user_id = veriifyResponse['data']['user_id']

    user_info_url = f"https://graph.facebook.com/{user_id}?fields=id,name,email&access_token={fbAccessToken}"
    user_info = requests.get(user_info_url).json()

    email = user_info.get('email')
    username = user_info.get('name') or email.split('@')[0]
    username = username.replace(' ', '_')

    userData = {
        'username': username,
        'email': email,
        'password': REMOTE_USER_PASSWORD
    }

    user = get_user(username, email)

    if (user is None):
        serializer = UserSerializer(data=userData)
        if serializer.is_valid():
            user = serializer.save()
            token = Token.objects.create(user=user)
            response_data = {
                'token': token.key,
                'user': serializer.data
            }
            return JsonResponse(response_data, status=status.HTTP_200_OK)
        return JsonResponse(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    else:
        token, created = Token.objects.get_or_create(user=user)
        serializer = UserSerializer(user)
        user.last_activity = timezone.now()
        user.save()
        return JsonResponse({'token': token.key, 'user': serializer.data}, status=status.HTTP_200_OK)


def get_user(username, email):
    try:
        user = get_object_or_404(User, username=username)
    except Http404:
        return None
    if user.email != email:
        return None
    return user


@api_view(['POST'])
def google_login_web(request):
    idToken = request.data.get('idToken')

    if not idToken:
        return JsonResponse({'error': 'idToken token not provided'}, status=status.HTTP_400_BAD_REQUEST)

    try:
        idInfo = id_token.verify_oauth2_token(idToken, google_requests.Request(), GOOGLE_CLIENT_ID_WEB)

    except ValueError:
        return JsonResponse({'error': 'Invalid idToken'}, status=status.HTTP_400_BAD_REQUEST)

    username = idInfo['name'] or idInfo['email'].split('@')[0]
    email = idInfo['email']

    if not username:
        return JsonResponse({'error': 'Username not provided'}, status=status.HTTP_400_BAD_REQUEST)

    if not email:
        return JsonResponse({'error': 'Email not provided'}, status=status.HTTP_400_BAD_REQUEST)

    username = username.replace(' ', '_')

    userData = {
        'username': username,
        'email': email,
        'password': REMOTE_USER_PASSWORD
    }

    user = get_user(username, email)

    if (user is None):
        serializer = UserSerializer(data=userData)
        if serializer.is_valid():
            user = serializer.save()
            token = Token.objects.create(user=user)
            response_data = {
                'token': token.key,
                'user': serializer.data
            }
            return JsonResponse(response_data, status=status.HTTP_200_OK)
        return JsonResponse(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    else:
        token, created = Token.objects.get_or_create(user=user)
        serializer = UserSerializer(user)
        user.last_activity = timezone.now()
        user.save()
        return JsonResponse({'token': token.key, 'user': serializer.data}, status=status.HTTP_200_OK)


@api_view(['POST'])
def google_login_app(request):
    idToken = request.data.get('idToken')

    if not idToken:
        return JsonResponse({'error': 'idToken token not provided'}, status=status.HTTP_400_BAD_REQUEST)

    try:
        idInfo = id_token.verify_oauth2_token(idToken, google_requests.Request(), GOOGLE_CLIENT_ID_APP)
    except ValueError:
        return JsonResponse({'error': 'Invalid idToken'}, status=status.HTTP_400_BAD_REQUEST)

    username = idInfo['name'] or idInfo['email'].split('@')[0]
    email = idInfo['email']

    if not username:
        return JsonResponse({'error': 'Username not provided'}, status=status.HTTP_400_BAD_REQUEST)

    if not email:
        return JsonResponse({'error': 'Email not provided'}, status=status.HTTP_400_BAD_REQUEST)

    username = username.replace(' ', '_')

    userData = {
        'username': username,
        'email': email,
        'password': REMOTE_USER_PASSWORD
    }

    user = get_user(username, email)

    if (user is None):
        serializer = UserSerializer(data=userData)
        if serializer.is_valid():
            user = serializer.save()
            token = Token.objects.create(user=user)
            response_data = {
                'token': token.key,
                'user': serializer.data
            }
            return JsonResponse(response_data, status=status.HTTP_200_OK)
        return JsonResponse(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    else:
        token, created = Token.objects.get_or_create(user=user)
        serializer = UserSerializer(user)
        user.last_activity = timezone.now()
        user.save()
        return JsonResponse({'token': token.key, 'user': serializer.data}, status=status.HTTP_200_OK)
