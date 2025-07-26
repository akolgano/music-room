from drf_spectacular.utils import extend_schema, OpenApiResponse, OpenApiExample
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