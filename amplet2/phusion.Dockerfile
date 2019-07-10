FROM phusion/baseimage:0.11

ENV COLLECTOR_ADDRESS collector
ENV DOMAIN ampca
ENV ROOTCERT /etc/amppki/cacert.pem

# Install prerequisites for installing other software
RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
		wget \
		iputils-ping

# Prepare rabbitmq install
RUN wget -qO- "https://github.com/rabbitmq/signing-keys/releases/download/2.0/rabbitmq-release-signing-key.asc" \
	| apt-key add -

RUN echo deb https://dl.bintray.com/rabbitmq-erlang/debian `lsb_release -c -s` erlang \\n\
		deb https://dl.bintray.com/rabbitmq/debian `lsb_release -c -s` main \
		> /etc/apt/sources.list.d/bintray.rabbitmq.list

# Prepare amplet2 install
RUN wget -qO- https://bintray.com/user/downloadSubjectPublicKey?username=wand | apt-key add -

RUN echo deb https://dl.bintray.com/wand/amp `lsb_release -c -s` main \
		> /etc/apt/sources.list.d/bintray.amplet2.list

# Install rabbitmq and amplet2
RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
		rabbitmq-server=3.7.15-1 amplet2-client syslog-ng

RUN apt-get autoremove -y \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Enable some plugins
RUN rabbitmq-plugins enable rabbitmq_shovel rabbitmq_management

# Get rabbitmqadmin from rabbitmq-server
RUN rabbitmq-server -detached \
	&& wget -qP /usr/local/bin localhost:15672/cli/rabbitmqadmin \
	&& chmod +x /usr/local/bin/rabbitmqadmin \
	&& sed -i "/#!\/usr\/bin\/env python/c\#!\/usr\/bin\/env python3" /usr/local/bin/rabbitmqadmin \
	&& rm -rf /var/log/rabbitmq/* /var/log/rabbitmq/*

COPY amplet.conf /etc/amplet2/clients/default.conf
COPY default.sched /etc/amplet2/schedules/default.sched

RUN mkdir /etc/service/amplet
COPY amplet.sh /etc/service/amplet/run
CMD ["/sbin/my_init"]
