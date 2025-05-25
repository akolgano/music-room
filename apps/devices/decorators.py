from functools import wraps
from rest_framework.response import Response
from apps.devices.models import Device, MusicControlDelegate

def require_device_control(view_func):
    @wraps(view_func)
    def _wrapped_view(request, *args, **kwargs):
        user = request.user
        device_uuid = request.data.get('device_uuid') or request.query_params.get('device_uuid')

        if not device_uuid:
            return Response({'error': 'Missing device_uuid'}, status=400)

        try:
            device = Device.objects.get(uuid=device_uuid)
        except Device.DoesNotExist:
            return Response({'error': 'Device not found'}, status=404)

        is_owner = device.user == user
        is_delegate = MusicControlDelegate.objects.filter(
            owner=device.user,
            delegate=user,
            device=device,
            can_control=True
        ).exists()

        if not (is_owner or is_delegate):
            return Response({'error': 'Permission denied for this device'}, status=403)

        request.device = device

        return view_func(request, *args, **kwargs)
    return _wrapped_view
