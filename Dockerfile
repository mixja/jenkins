FROM jenkins:2.32.3-alpine
MAINTAINER Justin Menga <justin.menga@gmail.com>
LABEL application=jenkins

# Change to root user
USER root

# Used to set the docker group ID
ARG DOCKER_GID
ARG TIMEZONE=America/Los_Angeles
COPY src/build/ /build/

# Install system requirements
RUN /build/set_gid.sh && \
  	echo "@community http://nl.alpinelinux.org/alpine/edge/community/" >> /etc/apk/repositories && \
  	apk add --no-cache --virtual build-dependencies python-dev openssl-dev libffi-dev musl-dev git gcc tzdata && \
    apk add --no-cache --update py-pip make docker@community jq && \
    cp /usr/share/zoneinfo/${TIMEZONE} /etc/localtime && \
    echo "${TIMEZONE}" >  /etc/timezone && \
    pip install --no-cache-dir -r /build/requirements.txt && \
    apk del build-dependencies && \
    rm -rf /build

# Change to jenkins user
USER jenkins

# Add Jenkins plugins
RUN /usr/local/bin/install-plugins.sh github dockerhub-notification workflow-aggregator zentimestamp swarm blueocean

# Add Jenkins home files
USER root
COPY src/jenkins/ ${JENKINS_HOME}/

# Entrypoint
COPY src/entrypoint.sh /usr/local/bin/entrypoint.sh
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]