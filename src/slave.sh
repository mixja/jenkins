#!/bin/bash
set -e

# Variable defaults
url=${JENKINS_URL:-http://jenkins:8080/}
username=${JENKINS_USERNAME:-admin}
labels=${JENKINS_SLAVE_LABELS:-docker}

# Start slave
exec java -jar slave.jar -master $url -username $username -passwordEnvVariable JENKINS_PASSWORD -executors 1 -labels ${labels}