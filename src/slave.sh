#!/bin/bash
set -e

# Start slave
exec java -jar slave.jar -master ${JENKINS_URL:-http://jenkins:8080/} -username ${JENKINS_USERNAME} -passwordEnvVariable JENKINS_PASSWORD -executors 1 -labels ${JENKINS_SLAVE_LABELS:-DOCKER}