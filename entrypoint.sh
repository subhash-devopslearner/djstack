#!/bin/sh

# Fix permissions for the static volume (run as root)
echo "Fixing permissions..."
chown -R django:django /app/staticfiles

# Ensure directories are searchable (755) and files are readable (644)
find /app/staticfiles -type d -exec chmod 755 {} +
find /app/staticfiles -type f -exec chmod 644 {} +

# Run migrations and collect static as the 'django' user
# 'su-exec' or 'gosu' are cleaner, but 'su' works in most images
echo "Running migrations and collectstatic..."
su django -s /bin/sh -c "python manage.py migrate --noinput"
su django -s /bin/sh -c "python manage.py collectstatic --noinput"

# Start Gunicorn as the 'django' user
echo "Starting Gunicorn..."
exec su django -s /bin/sh -c "gunicorn djstack.wsgi:application --bind 0.0.0.0:8000 --workers 3 --worker-tmp-dir /dev/shm"
