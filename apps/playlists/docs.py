from drf_spectacular.utils import extend_schema, OpenApiResponse, OpenApiExample, OpenApiParameter
from .docs_serializers import *
from apps.playlists.serializers import PlaylistLicenseSerializer


create_new_playlist_schema = extend_schema(
    methods=["POST"],
    summary="Create a new playlist",
    request=PlaylistCreateRequestSerializer,
    responses={
        201: OpenApiResponse(
            response=PlaylistCreateResponseSerializer,
            description="Playlist successfully created",
            examples=[
                OpenApiExample(
                    "Success",
                    value={
                        "message": "Empty playlist is created.",
                        "playlist_id": 1
                    }
                )
            ],
        ),
        400: OpenApiResponse(
            description="Missing Name",
            response=ErrorResponseSerializer,
            examples=[
                OpenApiExample(
                    "Missing name",
                    value={"error": "Playlist name is required."}
                )
            ],
        ),
        401: OpenApiResponse(
            description="Unauthorized",
            response=UnauthorizedResponseSerializer,
            examples=[
                OpenApiExample(
                    name="Unauthorized",
                    value={"detail": "Authentication credentials were not provided."},
                )
            ]
        ),
    },
)


get_playlist_info_schema = extend_schema(
    methods=["GET"],
    summary="Get playlist details",
    parameters=[
        OpenApiParameter(
            name="playlist_id",
            required=True,
            location=OpenApiParameter.PATH,
            type=int,
        )
    ],
    responses={
        200: OpenApiResponse(
            response=PlaylistInfoResponseSerializer,
            description="Playlist details retrieved successfully",
            examples=[
                OpenApiExample(
                    "Success",
                    value={
                        "playlist": [
                            {
                                "id": 1,
                                "playlist_name": "My Favorites",
                                "description": "All my favorite songs",
                                "public": True,
                                "creator": "user248",
                                "license_type": "open",
                                "tracks": [
                                    {"name": "Imagine", "artist": "John Lennon"},
                                    {"name": "Hey Jude", "artist": "The Beatles"}
                                ],
                                "shared_with": [
                                    {"id": "d2f1e240-bb4b-4b6a-bf62-aba9f915b111", "username": "user123"}
                                ]
                            }
                        ]
                    }
                )
            ]
        ),
        404: OpenApiResponse(
            response=ErrorResponseSerializer,
            description="Playlist not found",
            examples=[
                OpenApiExample(
                    name="Not Found",
                    value={"error": "Playlist not found."}
                ),
                OpenApiExample(
                    name="Not Found Playlist",
                    value={"detail": "No Playlist matches the given query."}
                ),
            ]
        ),
        401: OpenApiResponse(
            description="Unauthorized",
            response=UnauthorizedResponseSerializer,
            examples=[
                OpenApiExample(
                    name="Unauthorized",
                    value={"detail": "Authentication credentials were not provided."},
                )
            ]
        ),
    }
)


update_playlist_schema = extend_schema(
    methods=["PATCH"],
    summary="Update an existing playlist",
    parameters=[
        OpenApiParameter(
            name="playlist_id",
            location=OpenApiParameter.PATH,
            type=int,
            required=True,
        )
    ],
    request=PlaylistUpdateSerializer,
    responses={
        200: OpenApiResponse(
            response=PlaylistUpdateResponseSerializer,
            description="Playlist updated successfully",
            examples=[
                OpenApiExample(
                    "Success Example",
                    value={"message": "Playlist updated successfully."}
                )
            ]
        ),
        403: OpenApiResponse(
            response=ErrorResponseSerializer,
            description="User does not have permission to update this playlist",
            examples=[
                OpenApiExample(
                    "Permission Denied",
                    value={"error": "You do not have permission to edit this playlist."}
                )
            ]
        ),
        404: OpenApiResponse(
            response=ErrorResponseSerializer,
            description="Playlist not found",
            examples=[
                OpenApiExample(
                    "Not Found",
                    value={"error": "Not found."}
                ),
                OpenApiExample(
                    name="Not Found Playlist",
                    value={"detail": "No Playlist matches the given query."}
                ),
            ]
        ),
        401: OpenApiResponse(
            description="Unauthorized",
            response=UnauthorizedResponseSerializer,
            examples=[
                OpenApiExample(
                    name="Unauthorized",
                    value={"detail": "Authentication credentials were not provided."},
                )
            ]
        ),
    }
)


delete_playlist_schema = extend_schema(
    methods=["POST"],
    summary="Delete a playlist",
    parameters=[
        OpenApiParameter(
            name="playlist_id",
            location=OpenApiParameter.PATH,
            type=int,
            required=True,
        )
    ],
    responses={
        200: OpenApiResponse(
            response=PlaylistDeleteResponseSerializer,
            description="Playlist deleted successfully",
            examples=[
                OpenApiExample(
                    "Success",
                    value={"message": "Playlist deleted successfully."}
                )
            ]
        ),
        403: OpenApiResponse(
            response=ErrorResponseSerializer,
            description="User does not have permission to delete this playlist",
            examples=[
                OpenApiExample(
                    "Permission Denied",
                    value={"error": "You do not have permission to delete this playlist."}
                )
            ]
        ),
        404: OpenApiResponse(
            response=ErrorResponseSerializer,
            description="Playlist not found",
            examples=[
                OpenApiExample(
                    "Not Found",
                    value={"error": "Not found."}
                ),
                OpenApiExample(
                    name="Not Found Playlist",
                    value={"detail": "No Playlist matches the given query."}
                ),
            ]
        ),
        401: OpenApiResponse(
            description="Unauthorized",
            response=UnauthorizedResponseSerializer,
            examples=[
                OpenApiExample(
                    name="Unauthorized",
                    value={"detail": "Authentication credentials were not provided."},
                )
            ]
        ),
    }
)


playlist_tracks_schema = extend_schema(
    methods=["GET"],
    summary="Get playlist tracks",
    parameters=[
        OpenApiParameter(
            name="playlist_id",
            location=OpenApiParameter.PATH,
            type=int,
            required=True,
        )
    ],
    responses={
        200: OpenApiResponse(
            response=PlaylistTracksResponseSerializer,
            description="Playlist and its tracks retrieved successfully",
            examples=[
                OpenApiExample(
                    "Success",
                    value={
                        "playlist": "My Playlist",
                        "tracks": [
                            {
                                "track_id": 1,
                                "playlist_track_id": 10,
                                "deezer_track_id": "123456",
                                "name": "Track Title",
                                "position": 1,
                                "points": 0
                            },
                            {
                                "track_id": 2,
                                "playlist_track_id": 11,
                                "deezer_track_id": "654321",
                                "name": "Another Track",
                                "position": 2,
                                "points": 0
                            }
                        ]
                    }
                )
            ]
        ),
        404: OpenApiResponse(
            response=ErrorResponseSerializer,
            description="Playlist not found",
            examples=[
                OpenApiExample(
                    "Not Found",
                    value={"error": "Not found."}
                ),
                OpenApiExample(
                    name="Not Found Playlist",
                    value={"detail": "No Playlist matches the given query."}
                ),
            ]
        ),
        401: OpenApiResponse(
            description="Unauthorized",
            response=UnauthorizedResponseSerializer,
            examples=[
                OpenApiExample(
                    name="Unauthorized",
                    value={"detail": "Authentication credentials were not provided."},
                )
            ]
        ),
    }
)


add_track_schema = extend_schema(
    methods=["POST"],
    summary="Add track to playlist",
    parameters=[
        OpenApiParameter(
            name="playlist_id",
            location=OpenApiParameter.PATH,
            type=int,
            required=True,
        )
    ],
    request=AddTrackRequestSerializer,
    responses={
        201: OpenApiResponse(
            response=AddTrackSuccessSerializer,
            description="Track successfully added to playlist",
            examples=[
                OpenApiExample(
                    "Success",
                    value={"status": "track added", "track_id": 42}
                )
            ]
        ),
        400: OpenApiResponse(
            response=ErrorResponseSerializer,
            description="General error or track already in playlist",
            examples=[
                OpenApiExample("Already Exists", value={"error": "Track already in playlist"}),
                OpenApiExample("General Error", value={"error": "Some validation error"})
            ]
        ),
        404: OpenApiResponse(
            response=ErrorResponseSerializer,
            description="Playlist or Deezer track not found",
            examples=[
                OpenApiExample("Playlist Missing", value={"error": "Playlist not found"}),
                OpenApiExample("Deezer Missing", value={"error": "Track not found on Deezer"})
            ]
        ),
        405: OpenApiResponse(
            response=ErrorResponseSerializer,
            description="Method not allowed",
            examples=[
                OpenApiExample("Invalid Method", value={"error": "Invalid method"})
            ]
        ),
        401: OpenApiResponse(
            description="Unauthorized",
            response=UnauthorizedResponseSerializer,
            examples=[
                OpenApiExample(
                    name="Unauthorized",
                    value={"detail": "Authentication credentials were not provided."},
                )
            ]
        ),
    }
)


move_track_in_playlist_schema = extend_schema(
    methods=["POST"],
    summary="Reorder tracks in a playlist",
    parameters=[
        OpenApiParameter(
            name="playlist_id",
            location=OpenApiParameter.PATH,
            type=int,
            required=True,
        )
    ],
    request=MoveTrackRequestSerializer,
    responses={
        200: OpenApiResponse(
            response=MoveTrackSuccessSerializer,
            description="Tracks successfully reordered",
            examples=[
                OpenApiExample(
                    "Success",
                    value={"message": "Tracks reordered successfully"}
                )
            ]
        ),
        400: OpenApiResponse(
            response=ErrorResponseSerializer,
            description="Invalid input or general error",
            examples=[
                OpenApiExample("Invalid Range", value={"error": "Invalid range"}),
                OpenApiExample("General Error", value={"error": "Some validation error"})
            ]
        ),
        404: OpenApiResponse(
            response=ErrorResponseSerializer,
            description="Playlist not found",
            examples=[
                OpenApiExample("Playlist Missing", value={"error": "Playlist not found"})
            ]
        ),
        405: OpenApiResponse(
            response=ErrorResponseSerializer,
            description="Method not allowed",
            examples=[
                OpenApiExample("Invalid Method", value={"error": "Invalid method"})
            ]
        ),
        401: OpenApiResponse(
            description="Unauthorized",
            response=UnauthorizedResponseSerializer,
            examples=[
                OpenApiExample(
                    name="Unauthorized",
                    value={"detail": "Authentication credentials were not provided."},
                )
            ]
        ),
    }
)


delete_track_from_playlist_schema = extend_schema(
    methods=["POST"],
    summary="Delete a track from a playlist",
    parameters=[
        OpenApiParameter(
            name="playlist_id",
            location=OpenApiParameter.PATH,
            type=int,
            required=True,
        )
    ],
    request=DeleteTrackRequestSerializer,
    responses={
        200: OpenApiResponse(
            response=DeleteTrackSuccessSerializer,
            description="Track successfully deleted from playlist",
            examples=[
                OpenApiExample(
                    "Success",
                    value={"message": "Track deleted successfully"}
                )
            ]
        ),
        400: OpenApiResponse(
            response=ErrorResponseSerializer,
            description="General error or invalid body)",
            examples=[
                OpenApiExample("Invalid Body", value={"error": "Invalid JSON"}),
                OpenApiExample("General Error", value={"error": "Something went wrong"})
            ]
        ),
        404: OpenApiResponse(
            response=ErrorResponseSerializer,
            description="Playlist or track not found",
            examples=[
                OpenApiExample("Playlist Missing", value={"error": "Playlist not found"}),
                OpenApiExample("Track Missing", value={"error": "Track not found in playlist"})
            ]
        ),
        405: OpenApiResponse(
            response=ErrorResponseSerializer,
            description="Method not allowed",
            examples=[
                OpenApiExample("Invalid Method", value={"error": "Invalid method"})
            ]
        ),
        401: OpenApiResponse(
            description="Unauthorized",
            response=UnauthorizedResponseSerializer,
            examples=[
                OpenApiExample(
                    name="Unauthorized",
                    value={"detail": "Authentication credentials were not provided."},
                )
            ]
        ),
    }
)


get_user_saved_playlists_schema = extend_schema(
    methods=["GET"],
    summary="Get user saved or created playlists",
    responses={
        200: OpenApiResponse(
            response=UserSavedPlaylistsResponseSerializer,
            description="List of user saved or created playlists"
        ),
        401: OpenApiResponse(
            description="Unauthorized",
            response=UnauthorizedResponseSerializer,
            examples=[
                OpenApiExample(
                    name="Unauthorized",
                    value={"detail": "Authentication credentials were not provided."},
                )
            ]
        ),
    },
)


get_all_shared_playlists_schema = extend_schema(
    methods=["GET"],
    summary="Get all shared public playlists",
    responses={
        200: OpenApiResponse(
            response=SharedPlaylistsResponseSerializer,
            description="List of all shared public playlists"
        ),
        401: OpenApiResponse(
            description="Unauthorized",
            response=UnauthorizedResponseSerializer,
            examples=[
                OpenApiExample(
                    name="Unauthorized",
                    value={"detail": "Authentication credentials were not provided."},
                )
            ]
        ),
    },
)


change_visibility_schema = extend_schema(
    methods=["POST"],
    summary="Change playlist visibility",
    parameters=[
        OpenApiParameter(
            name="playlist_id",
            location=OpenApiParameter.PATH,
            type=int,
            required=True,
        )
    ],
    request=ChangeVisibilityRequestSerializer,
    responses={
        200: OpenApiResponse(
            response=ChangeVisibilityResponseSerializer,
            description="Playlist visibility updated successfully",
            examples=[
                OpenApiExample(
                    name="Success",
                    value={"message": "Playlist visibility changed successfully"},
                )
            ]
        ),
        400: OpenApiResponse(
            response=ErrorResponseSerializer,
            description="Invalid request or playlist not found",
            examples=[
                OpenApiExample(
                    name="Not found",
                    value={"error": "Playlist matching query does not exist."},
                )
            ]
        ),
        401: OpenApiResponse(
            description="Unauthorized",
            response=UnauthorizedResponseSerializer,
            examples=[
                OpenApiExample(
                    name="Unauthorized",
                    value={"detail": "Authentication credentials were not provided."},
                )
            ]
        ),
    },
)


invite_user_schema = extend_schema(
    methods=["POST"],
    summary="Invite user to playlist",
    parameters=[
        OpenApiParameter(
            name="playlist_id",
            location=OpenApiParameter.PATH,
            type=int,
            required=True,
        )
    ],
    request=InviteUserRequestSerializer,
    responses={
        201: OpenApiResponse(
            response=InviteUserResponseSerializer,
            description="User invited successfully",
            examples=[
                OpenApiExample(
                    name="Success",
                    value={"message": "User invited to the playlist"},
                )
            ]
        ),
        200: OpenApiResponse(
            response=InviteUserResponseSerializer,
            description="User already invited",
            examples=[
                OpenApiExample(
                    name="Already invited",
                    value={"message": "User already invited"},
                )
            ]
        ),
        400: OpenApiResponse(
            response=ErrorResponseSerializer,
            description="Invalid request"
        ),
        401: OpenApiResponse(
            description="Unauthorized",
            response=UnauthorizedResponseSerializer,
            examples=[
                OpenApiExample(
                    name="Unauthorized",
                    value={"detail": "Authentication credentials were not provided."},
                )
            ]
        ),
    },
)


patch_playlist_license_schema = extend_schema(
    methods=["PATCH", "GET"],
    summary="Get or Update playlist license",
    parameters=[
        OpenApiParameter(
            name="playlist_id",
            location=OpenApiParameter.PATH,
            type=int,
            required=True,
        )
    ],
    request=PlaylistLicenseSerializer,
    responses={
        200: OpenApiResponse(
            response=PlaylistLicenseSerializer,
        ),
        400: OpenApiResponse(
            description="Invalid data provided"
        ),
        403: OpenApiResponse(
            description="Permission denied or not the playlist creator",
            response=ErrorDetailSerializer,
            examples=[
                OpenApiExample(
                    name="Permission denied",
                    value={"detail": "You do not have permission to edit this playlist license."},
                )
            ]
        ),
        404: OpenApiResponse(
            description="Playlist not found",
            response=ErrorDetailSerializer,
            examples=[
                OpenApiExample(
                    name="Not found",
                    value={"detail": "Playlist not found"},
                )
            ]
        ), 
        401: OpenApiResponse(
            description="Unauthorized",
            response=UnauthorizedResponseSerializer,
            examples=[
                OpenApiExample(
                    name="Unauthorized",
                    value={"detail": "Authentication credentials were not provided."},
                )
            ]
        ),

    },
)


vote_for_track_schema = extend_schema(
    methods=["POST"],
    summary="Vote for a track in a playlist",
    parameters=[
        OpenApiParameter(
            name="playlist_id",
            location=OpenApiParameter.PATH,
            type=int,
            required=True,
        )
    ],
    request=VoteSerializer,
    responses={
        200: OpenApiResponse(
            response=PlaylistResponseSerializer,
            description="Vote registered and playlist updated"
        ),
        400: OpenApiResponse(
            description="Invalid data provided"
        ),
        403: OpenApiResponse(
            response=ErrorResponseSerializer,
            description="User has already voted in this playlist",
            examples=[
                OpenApiExample(
                    name="Already voted",
                    value={"error": "You have already voted for this playlist"},
                )
            ]
        ),
        404: OpenApiResponse(
            description="Playlist not found",
            response=ErrorDetailSerializer,
            examples=[
                OpenApiExample(
                    name="Not found",
                    value={"detail": "Playlist not found"},
                )
            ]
        ),
        401: OpenApiResponse(
            description="Unauthorized",
            response=UnauthorizedResponseSerializer,
            examples=[
                OpenApiExample(
                    name="Unauthorized",
                    value={"detail": "Authentication credentials were not provided."},
                )
            ]
        ),
    },
)


get_user_saved_events_schema = extend_schema(
    methods=["GET"],
    summary="Get user saved events",
    responses={
        200: EventsResponseSerializer,
        401: OpenApiResponse(
            description="Unauthorized",
            response=UnauthorizedResponseSerializer,
            examples=[
                OpenApiExample(
                    name="Unauthorized",
                    value={"detail": "Authentication credentials were not provided."},
                )
            ]
        ),
    },
)


get_all_shared_events_schema = extend_schema(
    methods=["GET"],
    summary="Get all shared events",
    responses={
        200: AllSharedEventsResponseSerializer,
        401: OpenApiResponse(
            description="Unauthorized",
            response=UnauthorizedResponseSerializer,
            examples=[
                OpenApiExample(
                    name="Unauthorized",
                    value={"detail": "Authentication credentials were not provided."},
                )
            ]
        ),
    },
)