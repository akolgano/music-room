import pytest
from apps.users.tests.conftest import authenticated_user
from apps.profile.models import VisibilityChoices


def test_create_profile(authenticated_user):
    """
        # authenticated_user created together with profile
    """
    user, _ = authenticated_user

    assert user.profile.user == user
    assert user.profile.avatar_visibility == VisibilityChoices.PUBLIC
    assert user.profile.name_visibility == VisibilityChoices.PUBLIC
    assert user.profile.location_visibility == VisibilityChoices.PUBLIC
    assert user.profile.bio_visibility == VisibilityChoices.PUBLIC
    assert user.profile.phone_visibility == VisibilityChoices.PRIVATE
    assert user.profile.friend_info_visibility == VisibilityChoices.FRIENDS
    assert user.profile.music_preferences_visibility == VisibilityChoices.PUBLIC
