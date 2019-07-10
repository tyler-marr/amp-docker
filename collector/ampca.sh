#!/bin/bash

# Generate rootcert if not done already
if [ ! -f /etc/amppki/certs/collector.03.pem ]; then
    # Wait for rabbit to be up
    while sleep 1; do
        rabbitmqctl node_health_check > /dev/null 2>&1
        status=$?
        if [ $status -eq 0 ]; then
            break
        fi
    done

    echo "Generating root certificate for collector..."
    ampca generate collector
fi

# Continually automatically sign any requests that come in. Should be replaced
# with more advanced filtering in a production environment.
while sleep 30; do
    certs=`ampca list | awk '{print $1;}'`
    if [[ ! -z $certs ]]; then
        ampca sign $certs
        echo $certs
    fi
done