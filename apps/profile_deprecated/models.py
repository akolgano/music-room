from django.db import models
from django.contrib.auth.models import User
from django.contrib.postgres.fields import ArrayField


class Profile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='profile')

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

    dob = models.DateField(
        null=True, 
        blank=True
    )
    
    hobbies = ArrayField(
        models.CharField(max_length=50),
        null=True,
        blank=True,
        default=list
    )

    friend_info = models.CharField(
        max_length=500,
        null=True,
        blank=True,
        default=''
    )

    music_preferences = ArrayField(
        models.CharField(max_length=50),
        null=True,
        blank=True,
        default=list
    )

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "User Profile"
        verbose_name_plural = "User Profiles"
        
    def __str__(self):
        return (
            f"user id: {self.user.id}, gender: {self.gender}, avatar: {self.avatar},"
            f"location: {self.location}, bio: {self.bio},"
            f"first_name: {self.first_name}, last_name: {self.last_name},"
            f"phone: {self.phone}, street: {self.street}, country: {self.country}, postal_code: {self.postal_code},"    
            f"dob: {self.dob}, hobbies: {self.hobbies}, friend_info: {self.friend_info},"
            f"music_preferences: {self.music_preferences}"
        )
