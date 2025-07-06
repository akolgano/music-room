from apps.users.models import Friendship
from django.db.models import Q

def is_friend(viewer, user):
    """
    Returns True if viewer and user are friends (friendship accepted).
    Assumes Friendship model has from_user, to_user, status.
    """
    return Friendship.objects.filter(
        Q(from_user=viewer, to_user=user, status='accepted') |
        Q(from_user=user, to_user=viewer, status='accepted')).exists()

def can_view_field(viewer, profile_owner, visibility):
    """
    Returns True if viewer can see a profile field based on its visibility.

    visibility values:
    - 'public': anyone can see
    - 'friends': only friends can see
    - 'private': only me (the profile owner)
    """
    if visibility == 'public':
        return True
    elif visibility == 'friends':
        return is_friend(viewer, profile_owner)
    elif visibility == 'private':
        return viewer == profile_owner
    return False