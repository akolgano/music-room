import pytest
from apps.profile.models import VisibilityChoices, MusicPreference
from PIL import Image
from django.core.files.uploadedfile import SimpleUploadedFile
import io


def user_init_profile(authenticated_user):

    user, _ = authenticated_user
    
    mp1 = MusicPreference.objects.create(name="rock")
    mp2 = MusicPreference.objects.create(name="jazz")

    user.profile.avatar = "user123_xxx.png"
    user.profile.avatar_visibility = VisibilityChoices.PUBLIC
    user.profile.name = "user123"
    user.profile.name_visibility = VisibilityChoices.PUBLIC
    user.profile.location = "SUTD"
    user.profile.location_visibility = VisibilityChoices.PUBLIC
    user.profile.bio = "Hello !"
    user.profile.bio_visibility = VisibilityChoices.PUBLIC
    user.profile.phone = "+6591234567"
    user.profile.phone_visibility = VisibilityChoices.PRIVATE
    user.profile.friend_info = "Hello Friend !"
    user.profile.friend_info_visibility = VisibilityChoices.FRIENDS
    user.profile.music_preferences.add(mp1, mp2)
    user.profile.music_preferences_visibility = VisibilityChoices.FRIENDS
    user.profile.save()

    return user


def make_image_file(filename="avatar.png", size=(10, 10), color=(255, 0, 0)):
    img = Image.new("RGB", size, color)
    buf = io.BytesIO()
    img.save(buf, format="PNG")
    buf.seek(0)
    return SimpleUploadedFile(filename, buf.read(), content_type="image/png")