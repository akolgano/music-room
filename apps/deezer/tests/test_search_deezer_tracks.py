import pytest
from django.urls import reverse
from rest_framework.test import APIClient
from unittest.mock import patch


def test_search_deezer_tracks_empty_query():
    """
        # Empty query string
        # Ensure reponse error {"error": "Query parameter 'q' is required."}
    """
    client = APIClient()
    url = reverse("deezer:search_deezer_tracks")

    response = client.get(url)
    assert response.status_code == 400
    assert response.json() == {"error": "Query parameter 'q' is required."}


@patch('apps.deezer.views.DeezerClient')
def test_search_deezer_tracks_api_failure(mock_deezer_client):
    """
        # Mock a fail deezer api call
        # Ensure reponse error {"error": "Failed to fetch data from Deezer."}
    """
    client = APIClient()
    url = reverse("deezer:search_deezer_tracks")

    mock_deezer_client.return_value.search_tracks.return_value = None

    response = client.get(url, {'q': 'test'})
    assert response.status_code == 502
    assert response.json() == {"error": "Failed to fetch data from Deezer."}


@patch('apps.deezer.views.DeezerClient')
def test_search_deezer_tracks_success(mock_deezer_client):
    """
        # Mock a deezer valid search response
        # Ensure reponse {"data": [{"id": 1, "title": "Test Track"}]}
    """
    client = APIClient()
    url = reverse("deezer:search_deezer_tracks")

    mock_results = {"data": [{"id": 1, "title": "Test Track"}]}
    mock_deezer_client.return_value.search_tracks.return_value = mock_results

    response = client.get(url, {'q': 'test'})
    assert response.status_code == 200
    assert response.json() == mock_results