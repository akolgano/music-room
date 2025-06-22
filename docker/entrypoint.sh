#!/bin/sh
mkdir -p /var/log

: > /var/log/django.log

echo "$(date): Starting the Django service..." >> /var/log/django.log

: ${POSTGRES_HOST:=postgres}
: ${POSTGRES_PORT:=5432}

echo "Waiting for database..."
while ! nc -z "$POSTGRES_HOST" "$POSTGRES_PORT"; do
  sleep 1
done
export PYTHONPATH=/app

echo "Applying migrations..."
python manage.py makemigrations
python manage.py migrate
echo "Loading data..."
if [ -f "/app/sample.json" ]; then
    python /app/clean_fixture.py /app/sample.json
elif [ -f "/app/apps/playlists/fixtures/sample.json" ]; then
    python /app/clean_fixture.py /app/apps/playlists/fixtures/sample.json
else
    echo "No sample.json found, skipping fixture cleaning"
fi

SUPERUSER_EXISTS=$(python manage.py shell -c "from django.contrib.auth import get_user_model; User = get_user_model(); print(User.objects.filter(username='$DJANGO_SUPERUSER_USERNAME').exists())")
if [ "$SUPERUSER_EXISTS" = "False" ]; then
  echo "Creating superuser..."
  python manage.py createsuperuser --noinput --username "$DJANGO_SUPERUSER_USERNAME" --email "$DJANGO_SUPERUSER_EMAIL"
else
  echo "Superuser already exists."
fi


# echo "Starting Gunicorn server..."
# exec gunicorn pong.wsgi:application --bind 0.0.0.0:8000


echo "Starting development server..."
#exec python manage.py runserver 0.0.0.0:8000
exec daphne -b 0.0.0.0 -p 8000 core.asgi:application
#exec uvicorn core.asgi:application --reload --host 0.0.0.0 --port 8000
