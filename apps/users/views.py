# ================================
# akolgano
# ================================

from rest_framework.decorators import api_view, authentication_classes, permission_classes
from rest_framework.response import Response
from rest_framework import status
from rest_framework.authtoken.models import Token
from .serializers import UserSerializer
from django.contrib.auth import get_user_model
from django.shortcuts import get_object_or_404
from rest_framework.authentication import TokenAuthentication
from rest_framework.permissions import IsAuthenticated
from django.http import Http404
from django.utils import timezone

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
