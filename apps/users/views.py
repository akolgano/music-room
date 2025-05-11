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
