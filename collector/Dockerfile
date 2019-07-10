FROM phusion/baseimage:0.11

# Install prerequisites for installing other software
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        wget \
        iputils-ping \
        net-tools \
        locate

# Prepare InfluxDB install
RUN wget -qO- https://repos.influxdata.com/influxdb.key | apt-key add -

RUN echo deb https://repos.influxdata.com/ubuntu `lsb_release -c -s` stable \
        > /etc/apt/sources.list.d/influxdb.list

# Prepare rabbitmq install
RUN wget -qO- "https://github.com/rabbitmq/signing-keys/releases/download/2.0/rabbitmq-release-signing-key.asc" \
    | apt-key add -

RUN echo deb https://dl.bintray.com/rabbitmq-erlang/debian `lsb_release -c -s` erlang \\n\
        deb https://dl.bintray.com/rabbitmq/debian `lsb_release -c -s` main \
        > /etc/apt/sources.list.d/bintray.rabbitmq.list

RUN mkdir -p /etc/rabbitmq \
	&& echo NODENAME=rabbit@collector > /etc/rabbitmq/rabbitmq-env.conf

# Prepare amppki, nntsc, and ampweb install
RUN wget -qO- "https://bintray.com/user/downloadSubjectPublicKey?username=wand" \
    | apt-key add -

RUN echo deb https://dl.bintray.com/wand/amp `lsb_release -c -s` main \
        > /etc/apt/sources.list.d/bintray.wand.list

RUN echo "amppki	amppki/fqdn	string	collector" | debconf-set-selections
RUN echo "ampy	ampy/views_user	string	guest" | debconf-set-selections
RUN echo "ampy	ampy/views_password	password	guest" | debconf-set-selections

# Install main service dependencies
RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
        postgresql \
        influxdb \
        memcached \
        python-influxdb \
        rabbitmq-server

# Enable some rabbit plugins
RUN rabbitmq-plugins enable rabbitmq_auth_mechanism_ssl rabbitmq_management

# Get rabbitmqadmin from rabbitmq-server
RUN echo "127.0.0.1\tcollector" >> /etc/hosts \
    && rabbitmq-server -detached \
    && wget -qP /usr/local/bin localhost:15672/cli/rabbitmqadmin \
    && chmod +x /usr/local/bin/rabbitmqadmin \
    && sed -i "/#!\/usr\/bin\/env python/c\#!\/usr\/bin\/env python3" /usr/local/bin/rabbitmqadmin

# Install main services
# nntsc and ampy need extra things running during install
COPY nntsc.conf /etc/nntsc/nntsc.conf
RUN echo "127.0.0.1\tcollector" >> /etc/hosts \
    && service postgresql start \
    && service influxdb start \
    && rabbitmq-server -detached \
    && DEBIAN_FRONTEND=noninteractive \
        apt-get install -y --no-install-recommends \
                -o DPkg::Options::="--force-confold" \
                amppki \
                nntsc \
                amp-web \
    && service postgresql stop \
    && service influxdb stop \
    && rabbitmqctl stop

# Tidy up
RUN apt-get autoremove -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
              /var/log/rabbitmq/* /var/log/rabbitmq/*

# Fix ownership of /etc/amppki
RUN chown -R ampweb /etc/amppki

# Set up entrypoint
RUN mkdir /etc/service/apache \
          /etc/service/influx \
          /etc/service/postgres \
          /etc/service/rabbit \
          /etc/service/nntsc \
          /etc/service/ampca \
          /etc/service/memcached

COPY apache.sh /etc/service/apache/run
COPY influx.sh /etc/service/influx/run
COPY postgres.sh /etc/service/postgres/run
COPY rabbit.sh /etc/service/rabbit/run
COPY nntsc.sh /etc/service/nntsc/run
COPY ampca.sh /etc/service/ampca/run
COPY memcached.sh /etc/service/memcached/run
RUN chmod +x /etc/service/*/run

COPY rabbitmq.config /etc/rabbitmq/rabbitmq.config
COPY ampweb.ini /etc/ampweb/production.ini

# Change the homepage on port 80 to redirect to ampweb
COPY redirect-to-ampweb.html /var/www/html/index.html

CMD ["/sbin/my_init"]