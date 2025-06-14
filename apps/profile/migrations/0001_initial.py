# Generated by Django 5.1 on 2025-06-15 04:01

import django.contrib.postgres.fields
import django.db.models.deletion
from django.conf import settings
from django.db import migrations, models


class Migration(migrations.Migration):

    initial = True

    dependencies = [
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
    ]

    operations = [
        migrations.CreateModel(
            name='ProfileFriend',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('dob', models.DateField(blank=True, null=True)),
                ('hobbies', django.contrib.postgres.fields.ArrayField(base_field=models.CharField(max_length=50), blank=True, default=list, size=None)),
                ('friend_info', models.CharField(blank=True, default='', max_length=500, null=True)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('user', models.OneToOneField(on_delete=django.db.models.deletion.CASCADE, related_name='profile_friend', to=settings.AUTH_USER_MODEL)),
            ],
            options={
                'verbose_name': 'User Friend Info',
                'verbose_name_plural': 'User Friend Infos',
            },
        ),
        migrations.CreateModel(
            name='ProfileMusic',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('music_preferences', django.contrib.postgres.fields.ArrayField(base_field=models.CharField(max_length=50), blank=True, default=list, size=None)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('user', models.OneToOneField(on_delete=django.db.models.deletion.CASCADE, related_name='profile_music', to=settings.AUTH_USER_MODEL)),
            ],
            options={
                'verbose_name': 'User Music Preference',
                'verbose_name_plural': 'User Music Preferences',
            },
        ),
        migrations.CreateModel(
            name='ProfilePrivate',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('first_name', models.CharField(blank=True, default='', max_length=50, null=True)),
                ('last_name', models.CharField(blank=True, default='', max_length=50, null=True)),
                ('phone', models.CharField(blank=True, default='', max_length=10, null=True)),
                ('street', models.CharField(blank=True, default='', max_length=100, null=True)),
                ('country', models.CharField(blank=True, default='', max_length=50, null=True)),
                ('postal_code', models.CharField(blank=True, default='', max_length=10, null=True)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('user', models.OneToOneField(on_delete=django.db.models.deletion.CASCADE, related_name='profile_private', to=settings.AUTH_USER_MODEL)),
            ],
            options={
                'verbose_name': 'User Private Info',
                'verbose_name_plural': 'User Private Infos',
            },
        ),
        migrations.CreateModel(
            name='ProfilePublic',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('gender', models.CharField(blank=True, choices=[('female', 'female'), ('male', 'male')], max_length=6, null=True)),
                ('avatar', models.CharField(blank=True, default='', max_length=100, null=True)),
                ('location', models.CharField(blank=True, default='', max_length=50, null=True)),
                ('bio', models.CharField(blank=True, default='', max_length=500, null=True)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('user', models.OneToOneField(on_delete=django.db.models.deletion.CASCADE, related_name='profile_public', to=settings.AUTH_USER_MODEL)),
            ],
            options={
                'verbose_name': 'User Public Info',
                'verbose_name_plural': 'User Public Infos',
            },
        ),
    ]
