from django.core.mail import EmailMultiAlternatives
import os


def send_forgot_password_email(otp, email, username):
    subject = 'OTP for reset password'
    text_content = f'User Name: {username}. Your OTP to reset password is {otp}. Expired in 5 minutes.'
    html_content = f'<p>User Name: {username}</p><p>Your OTP to reset password is <strong>{otp}</strong>. Expired in 5 minutes.</p>'

    msg = EmailMultiAlternatives(subject, text_content, os.environ.get('EMAIL_HOST_USER'), [email])
    msg.attach_alternative(html_content, "text/html")
    msg.send()
