#!/bin/bash
set -e

# Reset ownership on Jenkins home
chown -R jenkins:jenkins ${JENKINS_HOME}

# Handoff to default entrypoint
exec su -m jenkins -c "/bin/tini -- /usr/local/bin/jenkins.sh $@"