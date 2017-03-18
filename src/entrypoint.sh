#!/bin/bash
set -e

# Set default AWS region
export AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION:-us-west-2}

# Decrypt and convert KMS encrypted variables
kms=($(env | grep "^KMS_" || true))
for item in "${kms[@]}"
do
  key=$(sed 's|KMS_\([^=]*\)=\(.*\)|\1|' <<< $item)
  value=$(sed 's|\([^=]*\)=\(.*\)|\2|' <<< $item)
  decrypt=$(aws kms decrypt --ciphertext-blob fileb://<(echo "$value" | base64 -d)) 
  export $key="$(echo $decrypt | jq .Plaintext -r | base64 -d)"
done

# Handoff to appliction
exec "$@"