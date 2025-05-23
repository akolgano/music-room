import json
from channels.generic.websocket import AsyncWebsocketConsumer

class PlaylistConsumer(AsyncWebsocketConsumer):
    async def connect(self):
        self.playlist_id = self.scope['url_route']['kwargs']['playlist_id']
        self.group_name = f'playlist_{self.playlist_id}'
        print(f"WebSocket connected to playlist {self.playlist_id}")
        await self.channel_layer.group_add(self.group_name, self.channel_name)
        await self.accept()

    async def disconnect(self, close_code):
        print(f"WebSocket disconnected {close_code}")
        await self.channel_layer.group_discard(self.group_name, self.channel_name)

    async def playlist_update(self, event):
        print(f"Sending playlist update to the client: {event}")
        await self.send(text_data=json.dumps({
            'playlist_id': event['playlist_id'],
            'type': 'playlist_update',
            'data': event['data'],
        }))
