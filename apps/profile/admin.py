# Register your models here.

from django.contrib import admin

from .models import ProfilePublic
from .models import ProfilePrivate
from .models import ProfileFriend
from .models import ProfileMusic

admin.site.register(ProfilePublic)
admin.site.register(ProfilePrivate)
admin.site.register(ProfileFriend)
admin.site.register(ProfileMusic)
