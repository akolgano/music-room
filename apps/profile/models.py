from django.db import models
from django.contrib.auth.models import User
from django.contrib.postgres.fields import ArrayField


class ProfilePublic(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='profile_public')

    gender = models.CharField(
        max_length=6,
        choices=[('female', 'female'), ('male', 'male')],
        null=True,
        blank=True
        )
    
    avatar = models.CharField(
        max_length=100,
        null=True,
        blank=True,
        default=''
        )
    
    location = models.CharField(
        max_length=50,
        null=True,
        blank=True,
        default=''
        )
    
    bio = models.CharField(
        max_length=500,
        null=True,
        blank=True,
        default=''
        )

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "User Public Info"
        verbose_name_plural = "User Public Infos"
        
    def __str__(self):
        return (
            f"user id: {self.user.id}, gender: {self.gender}, avatar: {self.avatar},"
            f"location: {self.location}, bio: {self.bio}"
            )


class ProfilePrivate(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='profile_private')

    first_name = models.CharField(
        max_length=50,
        null=True,
        blank=True,
        default=''
        )
    
    last_name = models.CharField(
        max_length=50,
        null=True,
        blank=True,
        default=''
        )

    phone = models.CharField(
        max_length=10,
        null=True,
        blank=True,
        default=''
        )
    
    street = models.CharField(
        max_length=100,
        null=True,
        blank=True,
        default=''
        )
    
    country = models.CharField(
        max_length=50,
        null=True,
        blank=True,
        default=''
        )
    
    postal_code = models.CharField(
        max_length=10,
        null=True,
        blank=True,
        default=''
        )

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "User Private Info"
        verbose_name_plural = "User Private Infos"
        
    def __str__(self):
        return (
            f"user id: {self.user.id}, first_name: {self.first_name}, last_name: {self.last_name},"
            f"phone: {self.phone}, street: {self.street}, country: {self.country}, postal_code: {self.postal_code}"
            )


class ProfileFriend(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='profile_friend')

    dob = models.DateField(
        null=True, 
        blank=True
    )
    
    hobbies = ArrayField(
        models.CharField(max_length=50),
        blank=True,
        default=list
    )

    friend_info = models.CharField(
        max_length=500,
        null=True,
        blank=True,
        default=''
    )

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "User Friend Info"
        verbose_name_plural = "User Friend Infos"
        
    def __str__(self):
        return (
            f"user id: {self.user.id}, dob: {self.dob}, hobbies: {self.hobbies}, friend_info: {self.friend_info}"
        )


class ProfileMusic(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='profile_music')
    
    music_preferences = ArrayField(
        models.CharField(max_length=50),
        blank=True,
        default=list
    )

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "User Music Preference"
        verbose_name_plural = "User Music Preferences"
        
    def __str__(self):
        return (
            f"user id: {self.user.id}, music_preferences: {self.music_preferences}"
        )