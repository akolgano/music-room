from drf_spectacular.utils import extend_schema, OpenApiResponse, OpenApiExample
from .docs_serializers import *


facebook_login_schema = extend_schema(
    methods=["POST"],
    summary="Login or signup via Facebook access token",
    request=FacebookLoginRequestSerializer,
    responses={
        200: OpenApiResponse(
            description="Login successful, returns token and user info",
            response=FacebookLoginSuccessSerializer
        ),
        400: OpenApiResponse(
            description="Facebook login failed",
            response=ErrorSerializer,
            examples=[
                OpenApiExample(
                    name="Missing Access Token",
                    value={"error": "Access token not provided"},
                ),
                OpenApiExample(
                    name="Invalid FB Token",
                    value={"error": "Invalid Facebook access token"},
                ),
                OpenApiExample(
                    name="Invalid Credentials",
                    value={"error": "Invalid login credentials"},
                ),
                OpenApiExample(
                    name="Account Already Exists",
                    value={"error": "Already has a account with same email."},
                ),
            ]
        )
    }
)


google_login_schema = extend_schema(
    methods=["POST"],
    summary="Login or signup via Google",
    request=GoogleLoginRequestSerializer,
    responses={
        200: OpenApiResponse(
            description="Google login successful",
            response=GoogleLoginSuccessSerializer
        ),
        400: OpenApiResponse(
            description="Google login failed",
            response=ErrorSerializer,
            examples=[
                OpenApiExample(
                    name="Invalid idToken",
                    value={"error": "Invalid idToken"},
                ),
                OpenApiExample(
                    name="Missing Social Username",
                    value={"error": "Invalid social username"},
                ),
                OpenApiExample(
                    name="Missing Social Email",
                    value={"error": "Invalid social email"},
                ),
                OpenApiExample(
                    name="Missing Social ID",
                    value={"error": "Invalid social id"},
                ),
                OpenApiExample(
                    name="Account Exists",
                    value={"error": "Already has a account with same email."},
                ),
            ]
        )
    }
)


facebook_link_schema = extend_schema(
    methods=["POST"],
    summary="Link Facebook account to existing user",
    request=FacebookLinkRequestSerializer,
    responses={
        200: OpenApiResponse(
            description="Facebook account linked successfully",
            response=FacebookLinkSuccessSerializer
        ),
        400: OpenApiResponse(
            description="Failed to link Facebook account",
            response=ErrorSerializer,
            examples=[
                OpenApiExample(
                    name="Missing Token",
                    value={"error": "Access token not provided"},
                ),
                OpenApiExample(
                    name="Invalid FB Token",
                    value={"error": "Invalid Facebook access token"},
                ),
                OpenApiExample(
                    name="No FB Email",
                    value={"error": "Invalid login credentials"},
                ),
                OpenApiExample(
                    name="Already Linked",
                    value={"error": "Social network already linked"},
                ),
                OpenApiExample(
                    name="Email Conflict",
                    value={"error": "Email use by other user"},
                ),
                OpenApiExample(
                    name="Already In Use",
                    value={"error": "Email or Social network already in use"},
                ),
            ]
        ),
        401: OpenApiResponse(
            description="Unauthorized",
            response=ErrorSerializer,
            examples=[
                OpenApiExample(
                    name="Missing Auth",
                    value={"detail": "Authentication credentials were not provided."},
                )
            ]
        ),
    }
)


google_link_schema = extend_schema(
    methods=["POST"],
    summary="Link Google account to existing user",
    request=GoogleLinkRequestSerializer,
    responses={
        200: OpenApiResponse(
            description="Google account linked successfully",
            response=GoogleLinkSuccessSerializer
        ),
        400: OpenApiResponse(
            description="Failed to link Google account",
            response=ErrorSerializer,
            examples=[
                OpenApiExample(
                    name="Invalid Social Email",
                    value={"error": "Invalid social email"},
                ),
                OpenApiExample(
                    name="Token Invalid",
                    value={"error": "Invalid idToken"},
                ),
                OpenApiExample(
                    name="Already Linked",
                    value={"error": "Social network already linked"},
                ),
                OpenApiExample(
                    name="Email In Use",
                    value={"error": "Email use by other user"},
                ),
                OpenApiExample(
                    name="Already In Use",
                    value={"error": "Email or Social network already in use"},
                ),
            ]
        ),
        401: OpenApiResponse(
            description="Unauthorized",
            response=ErrorSerializer,
            examples=[
                OpenApiExample(
                    name="Unauthorized",
                    value={"detail": "Authentication credentials were not provided."},
                )
            ]
        ),
    }
)