from django.test import TestCase
from django.contrib.auth.models import User
from apps.users.serializers import UserSerializer  # adjust to your actual serializer


class UserSerializerTest(TestCase):
    def test_serializer_output(self):
        user = User.objects.create_user(username='test', email='test@example.com')
        serializer = UserSerializer(user)
        self.assertEqual(serializer.data['username'], 'test')
