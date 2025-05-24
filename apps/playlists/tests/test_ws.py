import pytest
from channels.testing import WebsocketCommunicator
from core.asgi import application
from channels.db import database_sync_to_async
from django.contrib.auth import get_user_model
from apps.playlists.models import Playlist

User = get_user_model()

@pytest.mark.django_db
@pytest.mark.asyncio
async def test_websocket_playlist_connect_and_receive():
    user = await database_sync_to_async(User.objects.create_user)(
        username="anna", password="Pass1234!"
    )
    
    playlist = await database_sync_to_async(Playlist.objects.create)(
        creator=user, description="Anna's Playlist"
    )
    communicator = WebsocketCommunicator(application, f"/ws/playlists/{playlist.id}/")
    connected, _ = await communicator.connect()
    assert connected

    await communicator.send_input({
        "type": "playlist_update",
        "playlist_id": playlist.id,
        "data": {
            "tracks": [{"id": 1, "position": "0"}]
        }
    })

    response = await communicator.receive_json_from()
    assert response["type"] == "playlist_update"
    assert response["playlist_id"] == playlist.id

    await communicator.disconnect()
