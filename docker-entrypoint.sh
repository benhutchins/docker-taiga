#!/bin/bash

# Setup database automatically if needed
if [ -z "$TAIGA_SKIP_DB_CHECK" ]; then
  python /checkdb.py
  DB_CHECK_STATUS=$?

  if [ $DB_CHECK_STATUS -eq 1 ]; then
    echo "Failed to connect to database server."
    exit 1
  elif [ $DB_CHECK_STATUS -eq 2 ]; then
    echo "Configuring initial database"
    python manage.py migrate --noinput
    python manage.py loaddata initial_user
    python manage.py loaddata initial_project_templates
    python manage.py loaddata initial_role
    python manage.py compilemessages
    python manage.py collectstatic --noinput
  fi
fi

# Automatically replace "TAIGA_HOSTNAME" with the environment variable
sed -i "s/TAIGA_HOSTNAME/$TAIGA_HOSTNAME/g" /taiga/conf.json

# Start nginx service (need to start it as background process)
# nginx -g "daemon off;"
service nginx start

# Start Taiga backend Django server
exec "$@"
