import pytest
from apps.users.tests.conftest import authenticated_user
from apps.profile.models import VisibilityChoices, MusicPreference
from apps.profile.serializers import ProfileSerializer


@pytest.mark.django_db
def test_profile_serializer(authenticated_user):

    user, _ = authenticated_user
    
    mp1 = MusicPreference.objects.create(name="rock")
    mp2 = MusicPreference.objects.create(name="jazz")

    user.profile.avatar = "user123_xxx.png"
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

    serializer = ProfileSerializer(user.profile)
    data = serializer.data

    assert data["avatar"] == "/apps/profile/avatars/user123_xxx.png"
    assert data["name"] == "user123"
    assert data["location"] == "SUTD"
    assert data["bio"] == "Hello !"
    assert data["phone"] == "+6591234567"
    assert data["friend_info"] == "Hello Friend !"
    assert set(data["music_preferences"]) == {"rock", "jazz"}
    assert data["name_visibility"] == VisibilityChoices.PUBLIC
    assert data["location_visibility"] == VisibilityChoices.PUBLIC
    assert data["bio_visibility"] == VisibilityChoices.PUBLIC
    assert data["phone_visibility"] == VisibilityChoices.PRIVATE
    assert data["friend_info_visibility"] == VisibilityChoices.FRIENDS
    assert data["music_preferences_visibility"] == VisibilityChoices.FRIENDS

