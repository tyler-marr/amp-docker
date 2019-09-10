FROM ubuntu:bionic

# Install prerequisites for installing other software
RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
		wget \
		gnupg \
		apt-transport-https \
		ca-certificates \
		lsb-release \
		iputils-ping \
		curl \
		vim \
		net-tools \
		locate

# Prepare rabbitmq install
RUN wget -qO- "https://github.com/rabbitmq/signing-keys/releases/download/2.0/rabbitmq-release-signing-key.asc" \
	| apt-key add -

RUN echo deb https://dl.bintray.com/rabbitmq-erlang/debian `lsb_release -c -s` erlang \\n\
		deb https://dl.bintray.com/rabbitmq/debian `lsb_release -c -s` main \
		> /etc/apt/sources.list.d/bintray.rabbitmq.list

RUN mkdir -p /etc/rabbitmq \
	&& echo NODENAME=rabbit@amplet > /etc/rabbitmq/rabbitmq-env.conf

# Prepare amplet2 install
RUN wget -qO- https://bintray.com/user/downloadSubjectPublicKey?username=wand | apt-key add -

RUN echo deb https://dl.bintray.com/wand/amp `lsb_release -c -s` main \
		> /etc/apt/sources.list.d/bintray.amplet2.list

# Install rabbitmq and amplet2
RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
		rabbitmq-server \
		amplet2-client

# Enable some plugins
RUN rabbitmq-plugins enable rabbitmq_shovel rabbitmq_management

# Get rabbitmqadmin from rabbitmq-server
RUN echo "127.0.0.1\tamplet" >> /etc/hosts \
	&& cat /etc/hosts \
	&& rabbitmq-server -detached \
	&& wget -qP /usr/local/bin localhost:15672/cli/rabbitmqadmin \
	&& chmod +x /usr/local/bin/rabbitmqadmin \
	&& sed -i "/#!\/usr\/bin\/env python/c\#!\/usr\/bin\/env python3" /usr/local/bin/rabbitmqadmin

# Tidy up
RUN apt-get autoremove -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
              /var/log/rabbitmq/* /var/log/rabbitmq/*

# Set up folder permissions properly
RUN mkdir -p /var/run/amplet2 /var/lib/rabbitmq/mnesia \
	&& chown amplet:amplet /var/run/amplet2 \
	&& chown rabbitmq:rabbitmq /var/lib/rabbitmq /var/lib/rabbitmq/mnesia

# Add rabbit user to amplet group so that rabbit can use the amplet key that was
# signed by the CA for communication with the collector.
RUN adduser rabbitmq amplet

# Disable rsyslogd kernel logging
RUN sed -e '/imklog/ s/^#*/#/' -i /etc/rsyslog.conf

# Copy default configurations, and set relevant environment variables.
COPY amplet.conf /etc/amplet2/clients/default.conf
COPY default.sched /etc/amplet2/schedules/default.sched
COPY rabbitmq.config /etc/rabbitmq/rabbitmq.config

ENV COLLECTOR_ADDRESS collector
ENV ROOTCERT /etc/amppki/cacert.pem

# RabbitMQ management UI
EXPOSE 15672

COPY docker-entrypoint.sh /
CMD ["/docker-entrypoint.sh"]
