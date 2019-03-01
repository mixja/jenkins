## Jenkins Base Image
FROM jenkins/jenkins:alpine as base
MAINTAINER Justin Menga <justin.menga@gmail.com>
LABEL application=jenkins

# Change to root user
USER root

# Used to set the docker group ID
ARG TIMEZONE=America/Los_Angeles
COPY src/build/ /build/

# Install system requirements
RUN apk add --no-cache --virtual build-dependencies python-dev openssl-dev libffi-dev musl-dev git gcc tzdata && \
    apk add --no-cache --update py-pip docker make curl git jq su-exec && \
    cp /usr/share/zoneinfo/${TIMEZONE} /etc/localtime && \
    echo "${TIMEZONE}" >  /etc/timezone && \
    pip install --no-cache-dir -r /build/requirements.txt && \
    apk del build-dependencies && \
    rm -rf /build

# Set default DOCKER_GID
ENV DOCKER_GID=0

### Jenkins Server Image
FROM base as jenkins

# Change to jenkins user
USER jenkins

# Add Jenkins plugins
RUN /usr/local/bin/install-plugins.sh github dockerhub-notification workflow-aggregator zentimestamp swarm blueocean ansible ansicolor

# Add Jenkins init files
COPY src/jenkins/ /usr/share/jenkins/ref/

# Entrypoint
COPY src/entrypoint.sh /usr/local/bin/entrypoint.sh
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["/sbin/tini","--","/usr/local/bin/jenkins.sh"]

# Change to root so that we can set Docker GID on container startup
USER root

### Jenkins Slave Image
FROM base as slave

# Install Jenkins Swarm Client
ARG JENKINS_SLAVE_VERSION
RUN curl --create-dirs -fsSLo /usr/share/jenkins/slave.jar https://repo.jenkins-ci.org/releases/org/jenkins-ci/plugins/swarm-client/${JENKINS_SLAVE_VERSION:-3.9}/swarm-client-${JENKINS_SLAVE_VERSION:-3.9}.jar
WORKDIR /usr/share/jenkins
USER jenkins

# Entrypoint
COPY src/entrypoint.sh /usr/local/bin/entrypoint.sh
COPY src/slave.sh /usr/local/bin/slave.sh
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["sh","/usr/local/bin/slave.sh"]

# Change to root so that we can set Docker GID on container startup
USER root