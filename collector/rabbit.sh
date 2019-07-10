#!/bin/bash

echo -e "127.0.0.1\tcollector" >> /etc/hosts

exec rabbitmq-server