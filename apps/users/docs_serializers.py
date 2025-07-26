from rest_framework import serializers


#shared
class ErrorResponseSerializer(serializers.Serializer):
    error = serializers.CharField()

class ErrorDetailSerializer(serializers.Serializer):
    detail = serializers.CharField()

class UnauthorizedResponseSerializer(serializers.Serializer):
    detail = serializers.CharField()


#forgot_password_schema
class ForgotPasswordRequestSerializer(serializers.Serializer):
    email = serializers.EmailField(help_text="User email")

class ForgotPasswordResponseSerializer(serializers.Serializer):
    username = serializers.CharField()
    email = serializers.EmailField()


#login_view_schema
class LoginRequestSerializer(serializers.Serializer):
    username = serializers.CharField()
    password = serializers.CharField(write_only=True)

class LoginUserSerializer(serializers.Serializer):
    id = serializers.IntegerField()
    username = serializers.CharField()
    email = serializers.EmailField()

class LoginResponseSerializer(serializers.Serializer):
    token = serializers.CharField()
    user = LoginUserSerializer()


#get_user_schema
class UserSocialSerializer(serializers.Serializer):
    type = serializers.CharField()
    social_id = serializers.CharField()
    social_email = serializers.EmailField()
    social_name = serializers.CharField()

class GetUserResponseSerializer(serializers.Serializer):
    username = serializers.CharField()
    id = serializers.IntegerField()
    email = serializers.EmailField()
    has_social_account = serializers.BooleanField()
    is_password_usable = serializers.BooleanField()
    social = UserSocialSerializer(required=False, allow_null=True)


#signup_schema
class SignupRequestSerializer(serializers.Serializer):
    otp = serializers.CharField()
    username = serializers.CharField()
    email = serializers.EmailField()
    password = serializers.CharField(write_only=True)

class UserResponseSerializer(serializers.Serializer):
    id = serializers.IntegerField()
    username = serializers.CharField()
    email = serializers.EmailField()

class SignupSuccessResponseSerializer(serializers.Serializer):
    token = serializers.CharField()
    user = UserResponseSerializer()

class ValidationErrorResponseSerializer(serializers.Serializer):
    username = serializers.ListField(child=serializers.CharField(), required=False)
    email = serializers.ListField(child=serializers.CharField(), required=False)
    password = serializers.ListField(child=serializers.CharField(), required=False)


#forgot_password_change_schema
class ForgotPasswordChangeRequestSerializer(serializers.Serializer):
    email = serializers.EmailField()
    otp = serializers.CharField()
    password = serializers.CharField(write_only=True)
    
class ForgotPasswordChangeResponseSerializer(serializers.Serializer):
    username = serializers.CharField()
    email = serializers.EmailField()
    

#signup_email_otp_schema
class SignupEmailOtpRequestSerializer(serializers.Serializer):
    email = serializers.EmailField()

class SignupEmailOtpResponseSerializer(serializers.Serializer):
    email = serializers.EmailField()


#user_password_change_schema
class ChangePasswordRequestSerializer(serializers.Serializer):
    current_password = serializers.CharField(write_only=True)
    new_password = serializers.CharField(write_only=True)

class ChangePasswordResponseSerializer(serializers.Serializer):
    username = serializers.CharField()
    email = serializers.EmailField()


#logout_view_schema
class LogoutRequestSerializer(serializers.Serializer):
    username = serializers.CharField()

class LogoutSuccessResponseSerializer(serializers.Serializer):
    detail = serializers.CharField()


#check_email
class CheckEmailRequestSerializer(serializers.Serializer):
    email = serializers.EmailField()

class CheckEmailResponseSerializer(serializers.Serializer):
    exists = serializers.BooleanField()