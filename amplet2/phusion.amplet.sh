#!/bin/bash

# Set up configuration according to environment variables if we need to
echo Starting amplet...

sed -i "/address = collector-address/c\    address = $COLLECTOR_ADDRESS" /etc/amplet2/clients/default.conf
sed -i "/cacert = cacert-file/c\    cacert = \/etc\/amppki\/certs\/$DOMAIN\.03\.pem" /etc/amplet2/clients/default.conf

# Wait for the root CA certificate to exist
until [[ -f /etc/amppki/certs/$DOMAIN.03.pem && -f $ROOTCERT ]]; do
	echo No root certificates. Sleeping 15 seconds before trying again
	sleep 15
done

# Trust the root CA certificate
ln -sf $ROOTCERT /usr/local/share/ca-certificates/root-cert.crt
update-ca-certificates > /dev/null

# Give the amplet a directory to put local sockets
mkdir -p /var/run/amplet2

exec /sbin/setuser amplet amplet2