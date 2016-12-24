FROM jenkins:2.7.4-alpine
MAINTAINER Justin Menga <justin.menga@gmail.com>

# Change to root user
USER root

# Used to set the docker group ID
ARG DOCKER_GID
COPY set_gid.sh /
RUN /set_gid.sh

# Install system requirements
RUN echo "http://nl.alpinelinux.org/alpine/edge/community/" >> /etc/apk/repositories && \
    apk add --no-cache --update py-pip docker make

# Install Docker Compose and Ansible
COPY packages /packages
RUN pip install --no-index --no-cache-dir -f /packages -r /packages/requirements.txt && \
    rm -rf /packages

# Change to jenkins user
USER jenkins

# Add Jenkins plugins
RUN /usr/local/bin/install-plugins.sh github dockerhub-notification workflow-aggregator zentimestamp swarm blueocean
