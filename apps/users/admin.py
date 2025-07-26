# Register your models here.

from django.contrib import admin

from .models import Friendship, CustomUser

admin.site.register(Friendship)
admin.site.register(CustomUser)