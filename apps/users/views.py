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
#from .models import CustomUser, Friendship
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

User = get_user_model()

@api_view(['POST'])
def login_view(request):
    username = request.data.get('username')
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
        return Response("Logout successfully")
    except Exception:
        return Response({"detail": "Logout failed."}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
def signup(request):
    otp_code = request.data.get('otp')
    email = request.data.get('email')

    otp = SignupOneTimePasscode.objects.filter(email=email, expired_at__gt=timezone.now()).first()
    if not otp:
        return JsonResponse({'error': 'Signup OTP not found or expired.'}, status=status.HTTP_400_BAD_REQUEST)

    if otp.code != otp_code:
        return JsonResponse({'error': 'Signup OTP not match'}, status=status.HTTP_400_BAD_REQUEST)

    social = SocialNetwork.objects.filter(email=email).first()
    if social:
        return JsonResponse({'error': 'Email already in use.'}, status=status.HTTP_400_BAD_REQUEST)

    serializer = UserSerializer(data=request.data)
    if serializer.is_valid():
        user = serializer.save()
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



@api_view(['POST'])
@authentication_classes([TokenAuthentication])
@permission_classes([IsAuthenticated])
def remove_friend(request, user_id):
    friendship = Friendship.objects.filter(
        Q(from_user=request.user, to_user=user_id) | Q(from_user=user_id, to_user=request.user))
    if not friendship:
        return JsonResponse({'message': 'You are not friends with this user.'}, status=status.HTTP_400_BAD_REQUEST)

    friendship.delete()
    return JsonResponse({'message': 'Friend removed successfully.'}, status=status.HTTP_200_OK)

@api_view(['GET'])
@authentication_classes([TokenAuthentication])
@permission_classes([IsAuthenticated])
def get_friends_list(request):
    user = request.user
    try:

        friends = Friendship.objects.filter(
        Q(from_user=request.user) | Q(to_user=request.user))
        friends_list = []
        for friend in friends:
            if friend.from_user.username == request.user.username:
                friend_id = friend.to_user.id
            else:
                friend_id = friend.from_user.id

            friends_list.append(friend_id)
        return JsonResponse({'friends': friends_list})
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=400)

@api_view(['POST'])
@authentication_classes([TokenAuthentication])
@permission_classes([IsAuthenticated])
def send_friend_request(request, user_id):
    to_user = get_object_or_404(User, id=user_id)
    if request.user.username == to_user.username:
        return JsonResponse({'message': 'You cannot add yourself as a friend.'}, status=status.HTTP_400_BAD_REQUEST)
    existing_friendship = Friendship.objects.filter(
        from_user=request.user, to_user=to_user
    ).first()

    if existing_friendship:
        return JsonResponse({'message': 'You already have a pending friend request or are already friends.'}, status=status.HTTP_400_BAD_REQUEST)
    friendship = Friendship.objects.create(from_user=request.user, to_user=to_user, status='pending')
    return JsonResponse({
        'message': f'Friend request sent to {to_user.username}.',
        'friend_id': to_user.id,
        'friendship_id': friendship.id,
    }, status=200)

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

@api_view(['POST'])
@authentication_classes([TokenAuthentication])
@permission_classes([IsAuthenticated])
def reject_friend_request(request, friendship_id):
    friendship = get_object_or_404(Friendship, id=friendship_id, to_user=request.user, status='pending')
    
    friendship.delete()
    return JsonResponse({
            "message": f'Friend request with {friendship.from_user.username} rejected!',
    }, status=200)


@api_view(['POST'])
def forgot_password(request):
    email = request.data.get('email')
    if not email:
        return JsonResponse({'error': 'Invalid email.'}, status=status.HTTP_400_BAD_REQUEST)

    user = User.objects.filter(email=email).first()
    if not user:
        return JsonResponse({'error': 'User not found.'}, status=status.HTTP_404_NOT_FOUND)

    if not user.has_usable_password():
        return JsonResponse({'error': 'User passwords cannot be reset.'}, status=status.HTTP_400_BAD_REQUEST)

    otp = utils.create_otp_for_user(user)

    if not otp:
        return JsonResponse({'error': 'OTP creation failed.'}, status=status.HTTP_404_NOT_FOUND)

    try:
        email_sender.send_forgot_password_email(otp.code, email, user.username)
    except Exception:
        return JsonResponse({'error': 'OTP email send failed.'}, status=status.HTTP_400_BAD_REQUEST)

    return JsonResponse({'username': user.username, 'email': user.email}, status=status.HTTP_200_OK)


@api_view(['POST'])
def forgot_change_password(request):
    email = request.data.get('email')
    otp_code = request.data.get('otp')
    password = request.data.get('password')

    if not email or not otp_code or not password:
        return JsonResponse({'error': 'Invalid email, otp or password.'}, status=status.HTTP_400_BAD_REQUEST)

    user = User.objects.filter(email=email).first()    
    if not user:
        return JsonResponse({'error': 'User not found.'}, status=status.HTTP_404_NOT_FOUND)

    if not user.has_usable_password():
        return JsonResponse({'error': 'User passwords cannot be reset.'}, status=status.HTTP_400_BAD_REQUEST)

    otp = OneTimePasscode.objects.filter(user=user, expired_at__gt=timezone.now()).first()
    if not otp:
        return JsonResponse({'error': 'OTP not found or expired.'}, status=status.HTTP_400_BAD_REQUEST)

    try:
        validate_password(password)
    except ValidationError as e:
        return JsonResponse({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)

    if otp.code == otp_code:
        user.set_password(password)
        user.save()
        return JsonResponse({'username': user.username, 'email' : user.email}, status=status.HTTP_200_OK)
    else:
        return JsonResponse({'error': 'OTP not match'}, status=status.HTTP_400_BAD_REQUEST)


@api_view(['POST'])
@authentication_classes([TokenAuthentication])
@permission_classes([IsAuthenticated])
def user_password_change(request):
    current_password = request.data.get('currentPassword')
    new_password = request.data.get('newPassword')
    user = request.user

    if not user.has_usable_password():
        return JsonResponse({'error': 'User passwords cannot be change.'}, status=status.HTTP_400_BAD_REQUEST)

    if not user.check_password(current_password):
        return JsonResponse({'error': 'Current passwords not match.'}, status=status.HTTP_400_BAD_REQUEST)

    try:
        validate_password(new_password)
    except ValidationError as e:
        return JsonResponse({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)

    user.set_password(new_password)
    user.save()
    return JsonResponse({'username': user.username, 'email' : user.email}, status=status.HTTP_200_OK)


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


@api_view(['POST'])
def signup_email_otp(request):
    email = request.data.get('email')

    if not email:
        return JsonResponse({'error': 'Invalid email'}, status=status.HTTP_400_BAD_REQUEST)
    
    otp = utils.create_otp_signup(email)

    if not otp:
        return JsonResponse({'error': 'Signup OTP creation failed.'}, status=status.HTTP_400_BAD_REQUEST)

    try:
        email_sender.send_signup_otp_email(otp.code, email)
    except Exception:
        return JsonResponse({'error': 'Signup OTP email send failed.'}, status=status.HTTP_400_BAD_REQUEST)

    return JsonResponse({'email': email}, status=status.HTTP_200_OK)
