from drf_spectacular.utils import extend_schema, OpenApiResponse, OpenApiExample
from .docs_serializers import *
from .serializers import ProfileSerializer, MusicPreferenceSerializer


profile_update_schema = extend_schema(
    methods=["PUT", "PATCH"],
    summary="Update the authenticated user's profile",
    request=ProfileSerializer,
    responses={
        200: OpenApiResponse(
            description="Profile updated successfully",
            response=ProfileSerializer,
        ),
        400: OpenApiResponse(
            description="Validation error",
            response=ErrorMultiSerializer,
        ),
    },
)


profile_detail_schema = extend_schema(
    methods=["GET"],
    summary="Retrieve a user profile",
    parameters=[
        {
            "name": "pk",
            "required": True,
            "in": "path",
            "description": "User ID",
            "schema": {"type": "string"},
        },
    ],
    responses={
        200: OpenApiResponse(
            description="Return profile details",
            response=ProfileSerializer
        ),
        401: OpenApiResponse(
            description="Authentication credentials invalid", 
            response=ErrorSerializer,
            examples=[
                OpenApiExample(
                    name="Unauthorized",
                    value={"detail": "Authentication credentials were not provided"},
                ),
                OpenApiExample(
                    name="Invalid Token",
                    value={"detail": "Invalid token."},
                ),
            ]
        ),
        404: OpenApiResponse(
            description="Profile not found", 
            response=ErrorSerializer,
            examples=[
                OpenApiExample(
                    name="Profile Not Found",
                    value={"detail": "No Profile matches the given query."},
                )
            ],
        ),
    },
)


delete_avatar_schema = extend_schema(
    methods=["DELETE"],
    summary="Delete current user's avatar",
    request=None,
    responses={
        204: OpenApiResponse(
            description="Avatar deleted successfully",
        ),
        400: OpenApiResponse(
            description="No avatar to delete",
            response=ErrorSerializer,
            examples=[
                OpenApiExample(
                    name="No Avatar",
                    value={"detail": "No avatar to delete."},
                )
            ],
        ),
        401: OpenApiResponse(
            description="Authentication credentials invalid", 
            response=ErrorSerializer,
            examples=[
                OpenApiExample(
                    name="Unauthorized",
                    value={"detail": "Authentication credentials were not provided"},
                ),
            ]
        ),
    },
)


music_preferences_list_schema = extend_schema(
    methods=["GET"],
    summary="List music preferences",
    responses={
        200: OpenApiResponse(
            description="A list of music preferences",
            response=MusicPreferenceSerializer(many=True)
        ),
        401: OpenApiResponse(
            description="Authentication credentials invalid", 
            response=ErrorSerializer,
            examples=[
                OpenApiExample(
                    name="Unauthorized",
                    value={"detail": "Authentication credentials were not provided"},
                ),
            ]
        ),
    },
)