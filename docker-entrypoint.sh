#!/bin/bash

# Sleep when asked to, to allow the database time to start
# before Taiga tries to run /checkdb.py below.
: ${TAIGA_SLEEP:=0}
sleep $TAIGA_SLEEP

: ${TAIGA_DB_CONNECT_TIMEOUT:=120}
DB_AVAILABLE=false
DB_TEST_START=$(date +%s)

# Setup database automatically if needed
if [ -z "$TAIGA_SKIP_DB_CHECK" ]; then
  while [ "$DB_AVAILABLE" = "false" ]; do
    echo "Running database check"
    python /checkdb.py
    DB_CHECK_STATUS=$?

    if [ $DB_CHECK_STATUS -eq 1 ]; then
      DB_FAILED_TIME=$(date +%s)
      if [[ $(($DB_FAILED_TIME-$DB_TEST_START)) -gt $TAIGA_DB_CONNECT_TIMEOUT ]]; then
        echo "Failed to connect to database for more than TAIGA_DB_CONNECT_TIMEOUT seconds. Exiting..."
        exit 1
      fi
      echo "Failed to connect to database server or database does not exist."
      sleep 10
    elif [ $DB_CHECK_STATUS -eq 2 ]; then
      DB_AVAILABLE=true
      echo "Configuring initial database"
      python manage.py migrate --noinput
      python manage.py loaddata initial_user
      python manage.py loaddata initial_project_templates
      python manage.py loaddata initial_role
      python manage.py compilemessages
    else
      DB_AVAILABLE="true"
    fi
  done
fi

# Look for static folder, if it does not exist, then generate it
if [ ! -d "/usr/src/taiga-back/static" ]; then
  python manage.py collectstatic --noinput
fi

# Automatically replace "TAIGA_HOSTNAME" with the environment variable
sed -i "s/TAIGA_HOSTNAME/$TAIGA_HOSTNAME/g" /taiga/conf.json

# Look to see if we should set the "eventsUrl"
if [ ! -z "$RABBIT_PORT_5672_TCP_ADDR" ]; then
  echo "Enabling Taiga Events"
  sed -i "s/eventsUrl\": null/eventsUrl\": \"ws:\/\/$TAIGA_HOSTNAME\/events\"/g" /taiga/conf.json
  mv /etc/nginx/taiga-events.conf /etc/nginx/conf.d/default.conf
fi

# Handle enabling/disabling SSL
if [ "$TAIGA_SSL_BY_REVERSE_PROXY" = "True" ]; then
  echo "Enabling external SSL support! SSL handling must be done by a reverse proxy or a similar system"
  sed -i "s/http:\/\//https:\/\//g" /taiga/conf.json
  sed -i "s/ws:\/\//wss:\/\//g" /taiga/conf.json
elif [ "$TAIGA_SSL" = "True" ]; then
  echo "Enabling SSL support!"
  sed -i "s/http:\/\//https:\/\//g" /taiga/conf.json
  sed -i "s/ws:\/\//wss:\/\//g" /taiga/conf.json
  mv /etc/nginx/ssl.conf /etc/nginx/conf.d/default.conf
elif grep -q "wss://" "/taiga/conf.json"; then
  echo "Disabling SSL support!"
  sed -i "s/https:\/\//http:\/\//g" /taiga/conf.json
  sed -i "s/wss:\/\//ws:\/\//g" /taiga/conf.json
fi

# Start nginx service (need to start it as background process)
# nginx -g "daemon off;"
service nginx start

# Start Taiga backend Django server
exec "$@"
