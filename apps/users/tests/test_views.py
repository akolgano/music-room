from rest_framework.test import APITestCase
from django.urls import reverse
from rest_framework import status
from django.contrib.auth import get_user_model
from rest_framework.authtoken.models import Token

User = get_user_model()

class UserSignupTests(APITestCase):
    def test_user_signup(self):
        url = reverse('users:signup')
        data = {
            'username': 'testuser',
            'password': 'TestPass123!',
            'email': 'test@example.com',
        }
        response = self.client.post(url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)

class LoginApiTests(APITestCase):

    def setUp(self):
        self.user = User.objects.create_user(username='testuser', password='testpassword', email = 'dummy')
        self.token, created = Token.objects.get_or_create(user=self.user)

    def test_login_success(self):
        url = reverse('users:login')
        data = {
            'username': 'testuser',
            'password': 'testpassword'
        }
        response = self.client.post(url, data, format='json')

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('token', response.data)
        self.assertEqual(response.data['token'], self.token.key)
        self.assertIn('user', response.data)
        self.assertEqual(response.data['user']['username'], 'testuser')

    def test_login_invalid_password(self):
        url = reverse('users:login')
        data = {
            'username': 'testuser',
            'password': 'wrongpassword'
        }
        response = self.client.post(url, data, format='json')

        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)
        self.assertEqual(response.data, {"detail": "Not found."})

    def test_login_user_not_found(self):
        url = reverse('users:login')
        data = {
            'username': 'nonexistentuser',
            'password': 'testpassword'
        }
        response = self.client.post(url, data, format='json')

        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)

class LogoutApiTests(APITestCase):

    def setUp(self):
        self.user = User.objects.create_user(username='testuser', password='testpassword', email = 'dummy')
        self.token, created = Token.objects.get_or_create(user=self.user)

    def test_logout_success(self):
        self.client.credentials(HTTP_AUTHORIZATION='Token ' + self.token.key)
        response = self.client.post('/users/logout/', {
            'username': 'testuser'
        }, format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('Logout successfully', response.data)

class SignupApiTests(APITestCase):
    
    def setUp(self):
        self.existing_user = User.objects.create_user(username='existinguser', password='testpassword', email = 'dummy')

    def test_signup_success(self):
        url = reverse('users:signup')
        data = {
            'username': 'newuser',
            'password': 'newpassword%',
            'email': 'dummy1@email.com'
        }
        response = self.client.post(url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)

        self.assertIn('token', response.data)
        self.assertIn('user', response.data)
        self.assertEqual(response.data['user']['username'], 'newuser')

        # Verify that the user was created in the database
        self.assertTrue(User.objects.filter(username='newuser').exists())

        # Verify that a token was created for the user
        user = User.objects.get(username='newuser')
        token = Token.objects.get(user=user)
        self.assertEqual(response.data['token'], token.key)

    def test_signup_missing_username(self):
        url = reverse('users:signup')
        data = {
            'password': 'newpassword',
            'email': 'dummy2'
        }
        response = self.client.post(url, data, format='json')

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('username', response.data)

    def test_signup_missing_password(self):
        url = reverse('users:signup')
        data = {
            'username': 'newuser',
            'email': 'dummy3'
        }
        response = self.client.post(url, data, format='json')

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_signup_short_password(self):
        url = reverse('users:signup')
        data = {
            'username': 'validuser',
            'password': '1',
            'email': 'dummy4@email.com'
        }
        response = self.client.post(url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertTrue('This password is too short', response.data)

    def test_signup_duplicate_username(self):
        url = reverse('users:signup')
        data = {
            'username': 'existinguser',
            'password': 'newpassword',
            'email': 'email'
        }
        response = self.client.post(url, data, format='json')

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('username', response.data)
        self.assertTrue(response.data['username'][0], 'A user with that username already exists.')

    def test_signup_empty_request(self):
        url = reverse('users:signup')
        response = self.client.post(url, {}, format='json')

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('username', response.data)

    def test_signup_space_in_password(self):
        url = reverse('users:signup')
        data = {
            'username': 'validuser',
            'password': 'space_in_password ',
            'email': 'dummy4@email.com'
        }
        response = self.client.post(url, data, format='json')

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertTrue(response.data, 'The password must not contain spaces.')
