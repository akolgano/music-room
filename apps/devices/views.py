from rest_framework.decorators import api_view, authentication_classes, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.authentication import TokenAuthentication
from django.http import JsonResponse
from apps.devices.models import Device, MusicControlDelegate
from apps.devices.serializers import DeviceSerializer, MusicControlDelegateSerializer
from django.contrib.auth import get_user_model

User = get_user_model()

@api_view(['POST'])
@authentication_classes([TokenAuthentication])
@permission_classes([IsAuthenticated])
def register_device(request):
    user = request.user
    data = request.data

    uuid = data.get("uuid")
    license_key = data.get("license_key")
    device_name = data.get("device_name", "Unnamed Device")

    if not uuid or not license_key:
        return Response({"error": "Missing uuid or license_key"}, status=400)
    try:
        device, created = Device.objects.update_or_create(
            uuid=uuid,
            defaults={
                "user": user,
                "license_key": license_key,
                "is_active": True,
            }
        )
        return JsonResponse({
            "message": "Device registered" if created else "Device updated",
            "device": DeviceSerializer(device).data
        })
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=400)


@api_view(['POST'])
@authentication_classes([TokenAuthentication])
@permission_classes([IsAuthenticated])
def delegate_control(request):
    user = request.user
    data = request.data

    device_uuid = data.get('device_uuid')
    delegate_user_id = data.get('delegate_user_id')
    can_control = data.get('can_control', True)

    if not device_uuid or not delegate_user_id:
        return JsonResponse({"error": "device_uuid and delegate_user_id are required"}, status=400)

    try:
        device = Device.objects.get(uuid=device_uuid, user=user)
    except Device.DoesNotExist:
        return JsonResponse({"error": "Device not found or not owned by you"}, status=404)

    try:
        delegate_user = User.objects.get(id=delegate_user_id)
    except User.DoesNotExist:
        return JsonResponse({"error": "Delegate user not found"}, status=404)

    delegation, created = MusicControlDelegate.objects.update_or_create(
        owner=user,
        delegate=delegate_user,
        device=device,
        defaults={'can_control': can_control}
    )

    serializer = MusicControlDelegateSerializer(delegation)
    return JsonResponse({
        "message": "Delegation created" if created else "Delegation updated",
        "delegation": serializer.data,
    })


@api_view(['GET'])
@authentication_classes([TokenAuthentication])
@permission_classes([IsAuthenticated])
def check_control_permission(request, device_uuid):
    user = request.user

    try:
        device = Device.objects.get(uuid=device_uuid)
    except Device.DoesNotExist:
        return JsonResponse({"error": "Device not found."}, status=404)

    if device.user == user:
        return JsonResponse({"can_control": True, "reason": "User owns the device."})

    has_permission = MusicControlDelegate.objects.filter(
        owner=device.user,
        delegate=user,
        device=device,
        can_control=True
    ).exists()

    return JsonResponse({"can_control": has_permission})
