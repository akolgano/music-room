import pytest
from django.urls import reverse
from rest_framework.test import APIClient
from unittest.mock import patch


@patch('apps.deezer.views.DeezerClient')
def test_get_deezer_track_not_found(mock_deezer_client):
    """
        # Mock track not found
        # Ensure reponse error {"error": "Track not found"}
    """
    client = APIClient()
    url = reverse("deezer:get_deezer_track", kwargs={'track_id': 999})

    mock_deezer_client.return_value.get_track.return_value = None

    response = client.get(url)
    assert response.status_code == 404
    assert response.json() == {"error": "Track not found"}


@patch('apps.deezer.views.DeezerClient')
def test_get_deezer_track_success(mock_deezer_client):
    """
        # Mock track return
        # Ensure reponse track_data
    """
    client = APIClient()
    url = reverse("deezer:get_deezer_track", kwargs={'track_id': 999})

    mock_track_data = {
        "id": 999,
        "title": "Test Track",
        "artist": {"name": "Test Artist"},
    }
    mock_deezer_client.return_value.get_track.return_value = mock_track_data

    response = client.get(url)
    assert response.status_code == 200
    assert response.json() == mock_track_data