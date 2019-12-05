#!/bin/bash

# Simple manager script taken from https://docs.docker.com/config/containers/multi-service_container/

# Set up configuration according to environment variables
sed -i "/address = collector-address/c\    address = $COLLECTOR_ADDRESS" /etc/amplet2/clients/default.conf

# Wait for the root CA certificate to exist
until [[ -f /etc/amppki/certs/$COLLECTOR_ADDRESS.03.pem && -f $ROOTCERT ]]; do
	echo No root certificates. Sleeping 15 seconds before trying again
	sleep 15
done

ln -sf /etc/amppki/cacert.pem /etc/amplet2/keys/$COLLECTOR_ADDRESS.pem

# Trust the root CA certificate
ln -sf $ROOTCERT /usr/local/share/ca-certificates/root-cert.crt
update-ca-certificates > /dev/null

echo -e "127.0.0.1\tamplet" >> /etc/hosts

# Start rabbitmq
rabbitmq-server &
status=$?
if [ $status -ne 0 ]; then
	echo "Failed to start rabbitmq-server: $status"
	exit $status
fi

# Wait for rabbit to be up
while sleep 5; do
	rabbitmqctl node_health_check > /dev/null 2>&1
	status=$?
	if [ $status -eq 0 ]; then
		break
	fi
done

echo "Starting amplet..."

# Start rsyslog for amplet logging - this is redirected to /dev/stdout by the Dockerfile
rsyslogd
tail --pid $$ -F /var/log/amplet2/amplet2.log &

# Start the amplet
amplet2 &

echo "Amplet started"

# Check if either process has died, and quit the container if so
# Nothing fancy, and supervisord would do a better job
while sleep 5; do
	# check for rabbitmq being alive
	rabbitmqctl node_health_check > /dev/null
	status=$?
	if [ $status -ne 0 ]; then
		echo "rabbitmq-server unreachable, stopping container"
		exit $status
	fi

	# check if amplet is still alive
	pgrep amplet2 > /dev/null
	status=$?
	if [ $status -ne 0 ]; then
		echo "amplet not running, stopping container"
		exit $status
	fi
done