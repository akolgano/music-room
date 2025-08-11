from drf_spectacular.utils import extend_schema, OpenApiResponse, OpenApiExample, OpenApiParameter
from .docs_serializers import *


signup_email_otp_schema = extend_schema(
    methods=["POST"],
    summary="Signup send OTP",
    request=SignupEmailOtpRequestSerializer,
    responses={
        201: OpenApiResponse(
            description="Signup OTP sent successfully",
            response=SignupEmailOtpResponseSerializer
        ),
        400: OpenApiResponse(
            description="Signup OTP sending failed",
            response=ErrorResponseSerializer,
            examples=[
                OpenApiExample(
                    name="No Email",
                    value={"error": "No email provided"},
                ),
                OpenApiExample(
                    name="Invalid Email",
                    value={"error": "Invalid email format"},
                ),
                OpenApiExample(
                    name="OTP Creation Failed",
                    value={"error": "Signup OTP creation failed"},
                ),
                OpenApiExample(
                    name="Email Sending Failed",
                    value={"error": "Signup OTP email sending failed"},
                ),
            ]
        )
    }
)


signup_schema = extend_schema(
    methods=["POST"],
    summary="Signup new user",
    request=SignupRequestSerializer,
    responses={
        201: OpenApiResponse(
            description="Signup successful, returns token and user info",
            response=SignupSuccessResponseSerializer
        ),
        404: OpenApiResponse(
            description="Signup failed due to error",
            response=ErrorResponseSerializer,
            examples=[
                OpenApiExample(
                    name="Signup Error",
                    value={
                        "error": "Signup OTP not found or expired | Signup OTP not match | Email already in use"
                    },
                ),
                OpenApiExample(
                    name="Signup OTP Not Match Error",
                    value={
                        "error": "Signup OTP not match"
                    },
                ),
                OpenApiExample(
                    name="Email In Use Error",
                    value={
                        "error": "Email already in use"
                    },
                )
            ]
        ),
        400: OpenApiResponse(
            description="Signup failed due to serializer error",
            response=ValidationErrorResponseSerializer,
            examples=[
                OpenApiExample(
                    name="Signup Validation Error",
                    value={
                        "username": ["Username is already taken."],
                        "email": ["Email is already taken."],
                        "password": ["Ensure this field has at least 8 characters."]
                    },
                )
            ]
        ),
    }
)


get_user_schema = extend_schema(
    methods=["GET"],
    summary="Get authenticated user details",
    responses={
        200: OpenApiResponse(
            description="User info with social account if available",
            response=GetUserResponseSerializer,
        ),
        400: OpenApiResponse(
            description="Get user info failed due to error",
            response=ErrorResponseSerializer,
        ),
        401: OpenApiResponse(
            description="Unauthorized",
            response=UnauthorizedResponseSerializer,
            examples=[
                OpenApiExample(
                    name="Unauthorized",
                    value={"detail": "Authentication credentials were not provided"},
                )
            ]
        ),
    }
)


forgot_password_schema = extend_schema(
    methods=["POST"],
    summary="Forgot password send OTP",
    request=ForgotPasswordRequestSerializer,
    responses={
        201: OpenApiResponse(
            description="OTP sent to user's email",
            response=ForgotPasswordResponseSerializer
        ),
        400: OpenApiResponse(
            description="Forgot password send failed due to error",
            response=ErrorResponseSerializer,
            examples=[
                OpenApiExample(
                    name="No Email",
                    value={"error": "No email provided"},
                ),
                OpenApiExample(
                    name="Password Cannot Be Change",
                    value={"error": "User password cannot be change"},
                ),
                OpenApiExample(
                    name="OTP Creation Failed",
                    value={"error": "OTP creation failed"},
                ),
                OpenApiExample(
                    name="OTP Email Failed",
                    value={"error": "OTP email sending failed"},
                ),
            ]
        ),
        404: OpenApiResponse(
            description="Forgot password send failed due to error",
            response=ErrorResponseSerializer,
            examples=[
                OpenApiExample(
                    name="User Not Found",
                    value={"error": "User not found"},
                ),
            ]
        )    
    }
)


login_view_schema = extend_schema(
    methods=["POST"],
    summary="User login",
    request=LoginRequestSerializer,
    responses={
        200: OpenApiResponse(
            description="Login successful, returns token and user info",
            response=LoginResponseSerializer
        ),
        404: OpenApiResponse(
            description="User not found or login failed",
            response=ErrorResponseSerializer,
            examples=[
                OpenApiExample(
                    name="User Not Found",
                    value={"detail": "User not found"},
                ),
                OpenApiExample(
                    name="Missing Credentials",
                    value={"detail": "Username or password not provided"},
                ),
                OpenApiExample(
                    name="Invalid Login",
                    value={"detail": "Not found"},
                ),
                OpenApiExample(
                    name="Not Found",
                    value={"detail": "Not found"},
                ),
            ]
        )
    }
)

                
forgot_change_password_schema = extend_schema(
    methods=["POST"],
    summary="Forgot password change password",
    request=ForgotPasswordChangeRequestSerializer,
    responses={
        201: OpenApiResponse(
            description="Forgot password change password successful, returns username and email",
            response=ForgotPasswordChangeResponseSerializer
        ),
        400: OpenApiResponse(
            description="Forgot password change password failed due to error",
            response=ErrorResponseSerializer,
            examples=[
                OpenApiExample(
                    name="Invalid Inputs",
                    value={"detail": "Invalid email, otp or password"},
                ),
                OpenApiExample(
                    name="User Not Found",
                    value={"detail": "User not found"},
                ),
                OpenApiExample(
                    name="Password Cannot Be Change",
                    value={"detail": "User password cannot be change"},
                ),
                OpenApiExample(
                    name="OTP Expired",
                    value={"detail": "OTP not found or expired"},
                ),
                OpenApiExample(
                    name="OTP Mismatch",
                    value={"detail": "OTP not match"},
                ),
                OpenApiExample(
                    name="Password Validation Error",
                    value={"detail": [
                        "This password is too short. It must contain at least 8 characters.",
                        "This password is too common.",
                        "This password is entirely numeric.",
                        "The password must not contain spaces."
                    ]},
                ),
            ]
        ),
        404: OpenApiResponse(
            description="Forgot password change password failed due to error",
            response=ErrorResponseSerializer,
            examples=[
                OpenApiExample(
                    name="User Not Found",
                    value={"error": "User not found"},
                ),
            ]
        )
    }
)


user_password_change_schema = extend_schema(
    methods=["POST"],
    summary="Login user change password",
    request=ChangePasswordRequestSerializer,
    responses={
        201: OpenApiResponse(
            description="Login user password change successful, returns username and email",
            response=ChangePasswordResponseSerializer
        ),
        400: OpenApiResponse(
            description="Login user password change failed due to error",
            response=ErrorResponseSerializer,
            examples=[
                OpenApiExample(
                    name="Validation Error",
                    value={"detail": "User password cannot be changed"},
                ),
                OpenApiExample(
                    name="Incorrect Current Password",
                    value={"detail": "Current password not match"},
                ),
                OpenApiExample(
                    name="Missing Password Provided",
                    value={"detail": "No current password or new password provided"},
                ),
                OpenApiExample(
                    name="Password Validation Error",
                    value={"detail": [
                        "This password is too short. It must contain at least 8 characters.",
                        "This password is too common.",
                        "This password is entirely numeric.",
                        "The password must not contain spaces."
                    ]},
                ),
            ]
        ),
        401: OpenApiResponse(
            description="Unauthorized",
            response=UnauthorizedResponseSerializer,
            examples=[
                OpenApiExample(
                    name="Unauthorized",
                    value={"detail": "Authentication credentials were not provided"},
                )
            ]
        )
    }
)


logout_view_schema = extend_schema(
    methods=["POST"],
    summary="Logout authenticated user",
    request=LogoutRequestSerializer,
    responses={
        200: OpenApiResponse(
            description="Logout successful",
            response=LogoutSuccessResponseSerializer,
            examples=[
                OpenApiExample(
                    name="Logout Success",
                    value={"detail": "Logout successfully"},
                )
            ]
        ),
        404: OpenApiResponse(
            description="User not found",
            response=ErrorDetailSerializer,
            examples=[
                OpenApiExample(
                    name="User Not Found",
                    value={"detail": "User not found."},
                )
            ]
        ),
        500: OpenApiResponse(
            description="Logout failed due to server error",
            response=ErrorDetailSerializer,
            examples=[
                OpenApiExample(
                    name="Logout Failed",
                    value={"detail": "Logout failed."},
                )
            ]
        ),
        401: OpenApiResponse(
            description="Unauthorized",
            response=UnauthorizedResponseSerializer,
            examples=[
                OpenApiExample(
                    name="Unauthorized",
                    value={"detail": "Invalid token."},
                )
            ]
        )
    }
)


check_email_schema = extend_schema(
    methods=["POST"],
    summary="Check if email exists in User or SocialNetwork",
    request=CheckEmailRequestSerializer,
    responses={
        200: OpenApiResponse(
            description="Returns whether the email exists in User or SocialNetwork table",
            response=CheckEmailResponseSerializer
        ),
    },
)


send_friend_request_schema = extend_schema(
    methods=["POST"],
    summary="Send a friend request",
    parameters=[
        OpenApiParameter(
            name="user_id",
            description="UUID of the user to send friend request to",
            required=True,
            location=OpenApiParameter.PATH,
            type=str,
            pattern=r'^[0-9a-fA-F-]{36}$',
        ),
    ],
    request=None,
    responses={
        201: OpenApiResponse(
            description="Friend request successfully sent",
            response=FriendRequestResponseSerializer,
            examples=[
                OpenApiExample(
                    name="Success",
                    value={
                        "message": "Friend request sent to user123.",
                        "friend_id": "550e8400-e29b-41d4-a716-446655440000",
                        "friendship_id": 1
                    },
                ),
            ]
        ),
        400: OpenApiResponse(
            description="Invalid friend request",
            response=ErrorMessageSerializer,
            examples=[
                OpenApiExample(
                    name="Self Request",
                    value={"message": "You cannot add yourself as a friend."}
                ),
                OpenApiExample(
                    name="Pending Request",
                    value={"message": "You already have a pending friend request."}
                ),
                OpenApiExample(
                    name="Already Friends",
                    value={"message": "You are already friends."}
                ),
            ]
        ),
        404: OpenApiResponse(
            description="User not found",
            response=ErrorMessageSerializer,
            examples=[
                OpenApiExample(
                    name="User Not Found",
                    value={"message": "Not found."}
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
    }
)


accept_friend_request_schema = extend_schema(
    methods=["POST"],
    summary="Accept a pending friend request",
    parameters=[
        OpenApiParameter(
            name="friendship_id",
            description="ID of the pending friendship request to accept",
            required=True,
            location=OpenApiParameter.PATH,
            type=int,
        ),
    ],
    request=None,
    responses={
        200: OpenApiResponse(
            description="Friend request accepted successfully",
            response=AcceptFriendRequestResponseSerializer,
            examples=[
                OpenApiExample(
                    name="Success",
                    value={"message": "You are now friends with user123!"}
                )
            ]
        ),
        404: OpenApiResponse(
            description="Friend request not found or not pending",
            response=ErrorMessageSerializer,
            examples=[
                OpenApiExample(
                    name="Not Found",
                    value={"message": "Not found."}
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
    }
)


get_pending_friend_request_schema = extend_schema(
    methods=["GET"],
    summary="Get pending friend requests received by the authenticated user",
    responses={
        200: OpenApiResponse(
            description="List of pending friend requests",
            response=PendingFriendRequestsResponseSerializer
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


reject_friend_request_schema = extend_schema(
    methods=["POST"],
    summary="Reject a pending friend request",
    parameters=[
        OpenApiParameter(
            name="friendship_id",
            description="ID of the pending friendship request to reject",
            required=True,
            location=OpenApiParameter.PATH,
            type=int,
        ),
    ],
    request=None,
    responses={
        200: OpenApiResponse(
            description="Friend request rejected successfully",
            response=RejectFriendRequestResponseSerializer,
            examples=[
                OpenApiExample(
                    name="Success",
                    value={"message": "Friend request with user123 rejected!"}
                )
            ]
        ),
        404: OpenApiResponse(
            description="Friend request not found or not pending",
            response=ErrorMessageSerializer,
            examples=[
                OpenApiExample(
                    name="Not Found",
                    value={"message": "Not found."}
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
    }
)


get_sent_friend_request_schema = extend_schema(
    methods=["GET"],
    summary="Get pending friend requests sent by the authenticated user",
    responses={
        200: OpenApiResponse(
            description="List of pending friend requests sent by user",
            response=SentFriendRequestsResponseSerializer
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


get_friends_list_schema = extend_schema(
    methods=["GET"],
    summary="Get list of friends for the authenticated user",
    responses={
        200: OpenApiResponse(
            description="List of friends",
            response=FriendsListResponseSerializer,
            examples=[
                OpenApiExample(
                    name="Friends List Example",
                    value={
                        "friends": [
                            {
                                "friend_id": "550e8400-e29b-41d4-a716-446655440000",
                                "friend_username": "user123",
                                "profile_picture_url": "http://example.com/media/user123.jpg"
                            },
                            {
                                "friend_id": "123e4567-e89b-12d3-a456-426614174000",
                                "friend_username": "user248",
                                "profile_picture_url": ""
                            }
                        ]
                    }
                )
            ]
        ),
        400: OpenApiResponse(
            description="Error retrieving friends list",
            response=ErrorResponseSerializer,
            examples=[
                OpenApiExample(
                    name="Error Example",
                    value={"error": "Detailed error message here."}
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
    }
)


remove_friend_schema = extend_schema(
    methods=["POST"],
    summary="Remove a friend",
    parameters=[
        OpenApiParameter(
            name="user_id",
            description="UUID of the friend to remove",
            required=True,
            location=OpenApiParameter.PATH,
            type=str,
            pattern=r'^[0-9a-fA-F-]{36}$',
        ),
    ],
    request=None,
    responses={
        200: OpenApiResponse(
            description="Friend removed successfully",
            response=RemoveFriendResponseSerializer,
            examples=[
                OpenApiExample(
                    name="Success",
                    value={"message": "Friend removed successfully."}
                )
            ]
        ),
        400: OpenApiResponse(
            description="Not friend error",
            response=ErrorMessageSerializer,
            examples=[
                OpenApiExample(
                    name="Not Friend",
                    value={"message": "You are not friends with this user."}
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
    }
)