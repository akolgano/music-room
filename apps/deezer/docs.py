from drf_spectacular.utils import extend_schema, OpenApiResponse, OpenApiExample, OpenApiParameter
from .docs_serializers import *


get_deezer_track_schema = extend_schema(
    methods=["GET"],
    summary="Retrieve a Deezer track by ID",
    parameters=[
        {
            "name": "track_id",
            "required": True,
            "in": "path",
            "description": "ID of the Deezer track",
            "schema": {"type": "string"},
        }
    ],
    responses={
        200: OpenApiResponse(
            description="Track info retrieved successfully",
            response=DeezerTrackSerializer,
        ),
        404: OpenApiResponse(
            description="Track not found",
            response=ErrorSerializer,
            examples=[
                OpenApiExample(
                    name="Track Not Found",
                    value={"error": "Track not found"},
                )
            ],
        ),
    }
)


search_deezer_tracks_schema = extend_schema(
    methods=["GET"],
    summary="Search Deezer tracks by query",
    parameters=[
        OpenApiParameter(
            name="q",
            required=True,
            location=OpenApiParameter.QUERY,
            description="Search query string",
            type=str,
        )
    ],
    responses={
        200: OpenApiResponse(
            description="List of tracks matching the search query",
            response=DeezerTrackSearchResponseSerializer,
        ),
        400: OpenApiResponse(
            description="Missing query parameter",
            response=ErrorSerializer,
            examples=[
                OpenApiExample(
                    name="Missing Query",
                    value={"error": "Query parameter 'q' is required."},
                )
            ],
        ),
        502: OpenApiResponse(
            description="Failed to fetch data from Deezer",
            response=ErrorSerializer,
            examples=[
                OpenApiExample(
                    name="Deezer API Failure",
                    value={"error": "Failed to fetch data from Deezer."},
                )
            ],
        ),
    }
)