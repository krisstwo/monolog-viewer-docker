#!/bin/sh

# Basic auth protection
if [ ! -z "${BASIC_AUTH_USERNAME}" ]; then
    if [ ! -f /etc/.htpasswd ]; then
        echo "Setting basic auth protection"
        htpasswd -bc /etc/.htpasswd "${BASIC_AUTH_USERNAME}" "${BASIC_AUTH_PASSWORD}" \
        && echo -e 'auth_basic "Restricted Area";\nauth_basic_user_file /etc/.htpasswd;' > /etc/nginx/conf.d/default_basic_auth.conf
    else
        echo "/etc/.htpasswd found skipping basic auth protection"
    fi
fi

exec "$@"