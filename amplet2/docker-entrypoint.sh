#!/bin/bash

# Simple manager script taken from https://docs.docker.com/config/containers/multi-service_container/

# Set up configuration according to environment variables
# sed -i "s/collector-address/$COLLECTOR_ADDRESS/g" /etc/amplet2/clients/default.conf

#Display intro duction message 
if [[ $RUN_AMP != "go" ]]; then 
	echo -e "Please re run the image with the following command args:"
	echo -e "\t--env RUN_AMP=go                     -- to remove this message"
	echo -e "\t-v \"amplet_keys:/etc/amplet2/keys\"   -- to persist keys"
	echo -e "\t-v \"amplet_rabbit:/var/lib/rabbitmq\" -- to persist rabbit config" 
	echo -e "\t--network=host"
	echo -e "\t--cap-add=NET_RAW"
	echo -e "\t--cap-add=NET_ADMIN"
	echo -e "\t--cap-add=NET_BIND_SERVICE"
	echo -e "If using a static IP:"
	echo -e "\t\t--add-host=\"amp-collector:<COLLECTOR-IP>\""
	echo -e "Otherwise have \"amp-collector\" resolve to the machine"
	echo -e "running the collector"
	exit -1
fi

# Wait for the root CA certificate to exist
if [[ ! -f /etc/amplet2/keys/amp-collector.pem ]]; then
	echo "Missing root cert, attempting to retrive...."
	wget amp-collector/cacert.pem -O /etc/amplet2/keys/amp-collector.pem
	if [[ $? -ne 0 ]]; then 
		echo "Can't retrieve root cert from amp-collector/cacert.pem"
		echo "Exiting"
		exit -1
	fi
fi


# Trust the root CA certificate
# ln -sf /etc/amplet2/keys/$COLLECTOR_ADDRESS.pem /usr/local/share/ca-certificates/root-cert.crt
# update-ca-certificates > /dev/null

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
		echo "local abbitmq-server unreachable, stopping container"
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