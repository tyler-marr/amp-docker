#!/bin/bash

# If apache is already running, don't run again
pgrep apache > /dev/null
status=$?
if [ $status -eq 0 ]; then
    while true; do
        sleep 60
    done
fi

# Set up configuration according to environment variables
echo -e "amppki\tamppki/fqdn\tstring\t`cat /etc/hostname`" | debconf-set-selections
DEBIAN_FRONTEND=noninteractive dpkg-reconfigure amppki 2> /dev/null

echo ServerName `cat /etc/hostname` >> /etc/apache2/apache2.conf

# Apache gets grumpy about PID files pre-existing
rm -f /var/run/apache2/apache2.pid

echo Starting apache...
exec apachectl -D FOREGROUND