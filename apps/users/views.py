# ================================
# akolgano
# ================================

from rest_framework.decorators import api_view, authentication_classes, permission_classes
from rest_framework.response import Response
from rest_framework import status
from rest_framework.authtoken.models import Token
from django.contrib.auth import get_user_model
from django.shortcuts import get_object_or_404
from rest_framework.authentication import TokenAuthentication
from rest_framework.permissions import IsAuthenticated
from django.http import Http404
from django.utils import timezone
from .serializers import UserSerializer, FriendSerializer
from .models import Friendship
from django.http import JsonResponse
from django.db.models import Q
from . import email_sender
from . import utils
from .models import OneTimePasscode
from .models import SignupOneTimePasscode
from django.contrib.auth.password_validation import validate_password
from django.core.exceptions import ValidationError
from apps.remote_auth.models import SocialNetwork
from apps.profile.models import Profile, VisibilityChoices
from django.contrib.auth.hashers import check_password
from django.db import transaction
import re
import logging
from drf_spectacular.utils import extend_schema
from .docs import *


User = get_user_model()


@login_view_schema
@api_view(['POST'])
def login_view(request):
    username = request.data.get('username')
    password = request.data.get('password')

    if not username or not password:
        return Response({"detail": "Username or password not provided"}, status=status.HTTP_404_NOT_FOUND)

    try:
        user = get_object_or_404(User, username=username)
    except Http404:
        return Response({"detail": "User not found."}, status=status.HTTP_404_NOT_FOUND)
    if not user.check_password(request.data['password']):
        return Response({"detail": "Not found."}, status=status.HTTP_404_NOT_FOUND)
    token, created = Token.objects.get_or_create(user=user)
    serializer = UserSerializer(user)
    user.last_activity = timezone.now()
    user.save()
    return Response({'token': token.key, 'user': serializer.data})


@logout_view_schema
@api_view(['POST'])
@authentication_classes([TokenAuthentication])
@permission_classes([IsAuthenticated])
def logout_view(request):
    username = request.data.get('username')
    try:
        user = get_object_or_404(User, username=username)
    except Http404:
        return Response({"detail": "User not found."}, status=status.HTTP_404_NOT_FOUND)
    try:
        request.user.auth_token.delete()
        user.save()
        return Response({"detail": "Logout successfully"}, status=status.HTTP_200_OK)
    except Exception:
        return Response({"detail": "Logout failed."}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@signup_schema
@api_view(['POST'])
def signup(request):
    otp_code = request.data.get('otp')
    email = request.data.get('email')

    otp = SignupOneTimePasscode.objects.filter(email=email, expired_at__gt=timezone.now()).first()
    if not otp:
        return JsonResponse({'error': 'Signup OTP not found or expired'}, status=status.HTTP_404_NOT_FOUND)

    if not check_password(otp_code, otp.code):
        return JsonResponse({'error': 'Signup OTP not match'}, status=status.HTTP_404_NOT_FOUND)

    SignupOneTimePasscode.objects.filter(email=email).delete()

    social = SocialNetwork.objects.filter(email=email).first()
    if social:
        return JsonResponse({'error': 'Email already in use'}, status=status.HTTP_404_NOT_FOUND)

    with transaction.atomic():
        serializer = UserSerializer(data=request.data)
        if serializer.is_valid():
            user = serializer.save()
            profile = Profile.objects.create(user = user)
            token = Token.objects.create(user=user)
            response_data = {
                'token': token.key,
                'user': serializer.data
            }
            return Response(response_data, status=status.HTTP_201_CREATED)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['GET'])
@authentication_classes([TokenAuthentication])
@permission_classes([IsAuthenticated])
def test_token(request):
    return Response("passed!")


@check_email_schema
@api_view(['POST'])
def check_email(request):
    email = request.data.get('email')
    
    email_exists = (
        SocialNetwork.objects.filter(email=email).exists() or
        User.objects.filter(email=email).exists()
    )
    
    return JsonResponse({'exists': email_exists}, status=status.HTTP_200_OK)


@remove_friend_schema
@api_view(['POST'])
@authentication_classes([TokenAuthentication])
@permission_classes([IsAuthenticated])
def remove_friend(request, user_id):
    friendship = Friendship.objects.filter(
        Q(from_user=request.user, to_user_id=user_id, status='accepted') |
        Q(from_user_id=user_id, to_user=request.user, status='accepted')
    )
    if not friendship.exists():
        return JsonResponse({'message': 'You are not friends with this user.'}, status=status.HTTP_400_BAD_REQUEST)

    friendship.delete()
    return JsonResponse({'message': 'Friend removed successfully.'}, status=status.HTTP_200_OK)


@get_friends_list_schema
@api_view(['GET'])
@authentication_classes([TokenAuthentication])
@permission_classes([IsAuthenticated])
def get_friends_list(request):
    user = request.user
    profile_picture_url = 'TODO'
    try:
        friendships = Friendship.objects.filter(
            Q(from_user=user) | Q(to_user=user),
            status='accepted'
        )
        
        friends_list = []
        for fr in friendships:
            friend = fr.to_user if fr.from_user == user else fr.from_user
            try:
                profile = Profile.objects.get(user=friend)
                profile_picture_url = ''
                if profile.avatar and profile.avatar_visibility in [VisibilityChoices.PUBLIC, VisibilityChoices.FRIENDS]:
                    profile_picture_url = profile.avatar.url
            except Profile.DoesNotExist:
                profile_picture_url = ''
            friends_list.append({
                'friend_id': friend.id,
                'friend_username': friend.username,
                "profile_picture_url": profile_picture_url,
            })

        return Response({'friends': friends_list})
    except Exception as e:
        return Response({'error': str(e)}, status=400)

@send_friend_request_schema
@api_view(['POST'])
@authentication_classes([TokenAuthentication])
@permission_classes([IsAuthenticated])
def send_friend_request(request, user_id):
    to_user = get_object_or_404(User, id=user_id)
    if request.user.username == to_user.username:
        return JsonResponse({'message': 'You cannot add yourself as a friend.'}, status=status.HTTP_400_BAD_REQUEST)
    existing_friendship = Friendship.objects.filter(
        Q(from_user=request.user, to_user=to_user) | Q(to_user=request.user, from_user=to_user)
    ).first()

    if existing_friendship and existing_friendship.status == 'pending':
        return Response({'message': 'You already have a pending friend request.'}, status=status.HTTP_400_BAD_REQUEST)
    if existing_friendship and existing_friendship.status == 'accepted':
        return Response({'message': 'You are already friends.'}, status=status.HTTP_400_BAD_REQUEST)
    friendship = Friendship.objects.create(from_user=request.user, to_user=to_user, status='pending')
    return JsonResponse({
        'message': f'Friend request sent to {to_user.username}.',
        'friend_id': to_user.id,
        'friendship_id': friendship.id,
    }, status=201)


@get_pending_friend_request_schema
@api_view(['GET'])
@authentication_classes([TokenAuthentication])
@permission_classes([IsAuthenticated])
def get_pending_friend_request(request):
    friendships = Friendship.objects.filter(to_user=request.user, status='pending')

    data = []
    for fr in friendships:
        from_user = fr.from_user

        profile_picture_url = ''
        try:
            profile = Profile.objects.get(user=from_user)
            if profile.avatar and profile.avatar_visibility == VisibilityChoices.PUBLIC:
                profile_picture_url = profile.avatar.url
        except Profile.DoesNotExist:
            pass

        data.append({
            'friend_id': from_user.id,
            'friend_username': from_user.username,
            'friendship_id': fr.id,
            'profile_picture_url': profile_picture_url,
            'status': fr.status,
        })

    return JsonResponse({'received_invitations': data}, status=200)


@get_sent_friend_request_schema
@api_view(['GET'])
@authentication_classes([TokenAuthentication])
@permission_classes([IsAuthenticated])
def get_sent_friend_request(request):

    friendships = Friendship.objects.filter(from_user=request.user, status='pending')


    data = []
    for fr in friendships:
        to_user = fr.to_user

        profile_picture_url = ''
        try:
            profile = Profile.objects.get(user=to_user)
            if profile.avatar and profile.avatar_visibility == VisibilityChoices.PUBLIC:
                profile_picture_url = profile.avatar.url
        except Profile.DoesNotExist:
            pass

        data.append({
            'friend_id': to_user.id,
            'friend_username': to_user.username,
            'friendship_id': fr.id,
            'profile_picture_url': profile_picture_url,
            'status': fr.status,
        })

    return JsonResponse({'sent_invitations': data}, status=200)


@accept_friend_request_schema
@api_view(['POST'])
@authentication_classes([TokenAuthentication])
@permission_classes([IsAuthenticated])
def accept_friend_request(request, friendship_id):
    friendship = get_object_or_404(Friendship, id=friendship_id, to_user=request.user, status='pending')
    friendship.status = 'accepted'
    friendship.save()
    return JsonResponse({
            "message": f'You are now friends with {friendship.from_user.username}!',
    }, status=200)


@reject_friend_request_schema
@api_view(['POST'])
@authentication_classes([TokenAuthentication])
@permission_classes([IsAuthenticated])
def reject_friend_request(request, friendship_id):
    friendship = get_object_or_404(Friendship, id=friendship_id, to_user=request.user, status='pending')
    
    friendship.delete()
    return JsonResponse({
            "message": f'Friend request with {friendship.from_user.username} rejected!',
    }, status=200)


@forgot_password_schema
@api_view(['POST'])
def forgot_password(request):
    email = request.data.get('email')
    if not email:
        return JsonResponse({'error': 'No email provided'}, status=status.HTTP_400_BAD_REQUEST)

    user = User.objects.filter(email=email).first()
    if not user:
        return JsonResponse({'error': 'User not found'}, status=status.HTTP_404_NOT_FOUND)

    if not user.has_usable_password():
        return JsonResponse({'error': 'User passwords cannot be reset'}, status=status.HTTP_400_BAD_REQUEST)

    otp_code = utils.create_otp_for_user(user)

    if not otp_code:
        return JsonResponse({'error': 'OTP creation failed'}, status=status.HTTP_404_NOT_FOUND)

    try:
        email_sender.send_forgot_password_email(otp_code, email, user.username)
    except Exception:
        return JsonResponse({'error': 'OTP email sending failed'}, status=status.HTTP_400_BAD_REQUEST)

    return JsonResponse({'username': user.username, 'email': user.email}, status=status.HTTP_201_CREATED)


@forgot_change_password_schema
@api_view(['POST'])
def forgot_change_password(request):
    email = request.data.get('email')
    otp_code = request.data.get('otp')
    password = request.data.get('password')

    if not email or not otp_code or not password:
        return JsonResponse({'error': 'Invalid email, otp or password'}, status=status.HTTP_400_BAD_REQUEST)

    user = User.objects.filter(email=email).first()    
    if not user:
        return JsonResponse({'error': 'User not found'}, status=status.HTTP_404_NOT_FOUND)

    if not user.has_usable_password():
        return JsonResponse({'error': 'User passwords cannot be reset'}, status=status.HTTP_400_BAD_REQUEST)

    otp = OneTimePasscode.objects.filter(user=user, expired_at__gt=timezone.now()).first()
    if not otp:
        return JsonResponse({'error': 'OTP not found or expired'}, status=status.HTTP_400_BAD_REQUEST)

    OneTimePasscode.objects.filter(user=user).delete()

    try:
        validate_password(password)
    except ValidationError as e:
        return JsonResponse({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)

    if check_password(otp_code, otp.code):
        user.set_password(password)
        user.save()
        return JsonResponse({'username': user.username, 'email' : user.email}, status=status.HTTP_201_CREATED)
    else:
        return JsonResponse({'error': 'OTP not match'}, status=status.HTTP_400_BAD_REQUEST)


@user_password_change_schema
@api_view(['POST'])
@authentication_classes([TokenAuthentication])
@permission_classes([IsAuthenticated])
def user_password_change(request):
    current_password = request.data.get('current_password')
    new_password = request.data.get('new_password')
    user = request.user

    if not current_password or not new_password:
        return JsonResponse({'error': 'No current password or new password provided'}, status=status.HTTP_400_BAD_REQUEST)

    if not user.has_usable_password():
        return JsonResponse({'error': 'User password cannot be change'}, status=status.HTTP_400_BAD_REQUEST)

    if not user.check_password(current_password):
        return JsonResponse({'error': 'Current password not match'}, status=status.HTTP_400_BAD_REQUEST)

    try:
        validate_password(new_password)
    except ValidationError as e:
        return JsonResponse({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)

    user.set_password(new_password)
    user.save()
    return JsonResponse({'username': user.username, 'email' : user.email}, status=status.HTTP_201_CREATED)


@get_user_schema
@api_view(['GET'])
@authentication_classes([TokenAuthentication])
@permission_classes([IsAuthenticated])
def get_user(request):
    user = request.user

    try:
        data = {
            'username': user.username,
            'id': user.id,
            'email': user.email,
            'has_social_account': False,
            'is_password_usable': user.has_usable_password(),        
        }
        social = SocialNetwork.objects.filter(user=user).first()
        if social:
            data.update({
                'has_social_account': True,
                'social': {
                    'type': social.type,
                    'social_id': social.social_id,
                    'social_email': social.email,
                    'social_name': social.name
                }
            })
        return JsonResponse(data, status=status.HTTP_200_OK)
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)


@signup_email_otp_schema
@api_view(['POST'])
def signup_email_otp(request):
    email = request.data.get('email')

    if not email:
        return JsonResponse({'error': 'No email provided'}, status=status.HTTP_400_BAD_REQUEST)
    
    email_regex = r'^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$'
    if not re.match(email_regex, email):
        return JsonResponse({'error': 'Invalid email format'}, status=status.HTTP_400_BAD_REQUEST)
    
    otp_code = utils.create_otp_signup(email)
    if not otp_code:
        return JsonResponse({'error': 'Signup OTP creation failed'}, status=status.HTTP_400_BAD_REQUEST)

    try:
        email_sender.send_signup_otp_email(otp_code, email)
    except Exception:
        return JsonResponse({'error': 'Signup OTP email sending failed'}, status=status.HTTP_400_BAD_REQUEST)

    return JsonResponse({'email': email}, status=status.HTTP_201_CREATED)

logger = logging.getLogger(__name__)

@api_view(['POST'])
@authentication_classes([TokenAuthentication])
@permission_classes([])
def log_activity(request):
    try:
        logs = request.data.get('logs', [])
        batch_size = request.data.get('batch_size', len(logs))

        user_id = None
        if request.user.is_authenticated:
            user_id = request.user.id

        for log_entry in logs:
            log_message = f"User Activity: {log_entry.get('action', 'unknown')} on {log_entry.get('screen', 'unknown')}"

            context = {
                'user_id': user_id or log_entry.get('user_id'),
                'timestamp': log_entry.get('timestamp'),
                'platform': log_entry.get('platform', 'mobile'),
                'metadata': log_entry.get('metadata', {}),
            }

            logger.info(log_message, extra={'context': context})

        return JsonResponse({'status': 'success', 'received_logs': len(logs), 'batch_size': batch_size}, status=status.HTTP_200_OK)

    except Exception as e:
        logger.error(f"Error processing activity logs: {str(e)}")
        return JsonResponse({'status': 'error', 'message': 'Failed to process logs'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
