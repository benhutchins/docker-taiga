#!/bin/bash

# Sleep when asked to, to allow the database time to start
# before Taiga tries to run /checkdb.py below.
: ${TAIGA_SLEEP:=0}
sleep $TAIGA_SLEEP

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
  fi
fi

# Look for static folder, if it does not exist, then generate it
if [ ! -d "/usr/src/taiga-back/static" ]; then
  python manage.py collectstatic --noinput
fi

# Automatically replace "TAIGA_HOSTNAME" with the environment variable
sed -i "s/TAIGA_HOSTNAME/$TAIGA_HOSTNAME/g" /taiga/conf.json

# Look to see if we should set the "eventsUrl"
if [ ! -z "$RABBIT_PORT_5672_TCP_ADDR" ]; then
  sed -i "s/eventsUrl\": null/eventsUrl\": \"ws:\/\/$TAIGA_HOSTNAME\/events\"/g" /taiga/conf.json
fi

# Handle enabling SSL
if [ "$TAIGA_SSL" = "True" ]; then
  echo "Enabling SSL support!"
  sed -i "s/http:\/\//https:\/\//g" /taiga/conf.json
  sed -i "s/ws:\/\//wss:\/\//g" /taiga/conf.json
  mv /etc/nginx/ssl.conf /etc/nginx/conf.d/default.conf
fi

# Start nginx service (need to start it as background process)
# nginx -g "daemon off;"
service nginx start

# Start Taiga backend Django server
exec "$@"
