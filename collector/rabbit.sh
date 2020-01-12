#!/bin/bash

echo -e "127.0.0.1\tamp-collector" >> /etc/hosts

exec rabbitmq-server