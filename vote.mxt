curl -X POST http://localhost:8000/playlists/1/tracks/vote/ \
  -H "Authorization: Token d6a357995d063d4ece0ee94c30f6e008d5812ac7" \
  -H "Content-Type: application/json" \
  -H "X-User-Latitude: 1.3521" \
  -H "X-User-Longitude: 103.8198" \
  -d '{"range_start": 3}'



  curl -X PATCH http://localhost:8000/playlists/1/license/ \
  -H "Authorization: Token d6a357995d063d4ece0ee94c30f6e008d5812ac7" \
  -H "Content-Type: application/json" \
  -d '{
    "license_type": "location_time",
    "vote_start_time": "11:00:00",
    "vote_end_time": "18:00:00",
    "latitude": 1.3521,
    "longitude": 103.8198,
    "allowed_radius_meters": 500
  }'


  or 

    -d '{
    "license_type": "invite_only"
  }'

    -d '{
    "license_type": "open"
  }'