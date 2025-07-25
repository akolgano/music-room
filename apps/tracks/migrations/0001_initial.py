# Generated by Django 5.1 on 2025-07-26 07:49

from django.db import migrations, models


class Migration(migrations.Migration):

    initial = True

    dependencies = [
    ]

    operations = [
        migrations.CreateModel(
            name='Track',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('name', models.CharField(max_length=255)),
                ('artist', models.CharField(max_length=255)),
                ('deezer_track_id', models.CharField(default=0, max_length=255, unique=True)),
                ('album', models.CharField(blank=True, max_length=255, null=True)),
                ('url', models.URLField(default='')),
            ],
        ),
    ]
