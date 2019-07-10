#!/bin/bash

echo Starting influxdb...
exec /sbin/setuser influxdb influxd run >> /var/log/influxd.log 2>&1