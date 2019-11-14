#!/bin/bash

# Wait around for dependent services to start...
# We could do this actively, but this should be long enough.
sleep 10

exec /sbin/setuser cuz nntsc -C '/etc/nntsc/nntsc.conf'
