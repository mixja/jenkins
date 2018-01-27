#!/bin/bash
set -e

# Set Docker GID
if [ -n "${DOCKER_GID}" ]; then
  IFS=':' read -ra group <<< "$(getent group ${DOCKER_GID})"
  if [ -n "$group" ]; then
    addgroup jenkins $group
  else
    addgroup -g "${DOCKER_GID}" "${DOCKER_GID}"
    addgroup jenkins "${DOCKER_GID}"
  fi
fi

# Set default AWS region
export AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION:-us-west-2}

# Decrypt and convert KMS encrypted variables
kms=($(env | grep "^KMS_" || true))
for item in "${kms[@]}"
do
  key=$(sed 's|KMS_\([^=]*\)=\(.*\)|\1|' <<< $item)
  value=$(sed 's|\([^=]*\)=\(.*\)|\2|' <<< $item)
  if [[ -n "$value" ]]; then
    decrypt=$(aws kms decrypt --ciphertext-blob fileb://<(echo "$value" | base64 -d))
    export $key="$(echo $decrypt | jq .Plaintext -r | base64 -d)"
  fi
done

# Handoff to application as Jenkins user
export HOME=${JENKINS_HOME}
exec su-exec jenkins "$@"