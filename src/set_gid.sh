#!/bin/bash
set -e

if [ -n "${DOCKER_GID}" ]; then
  IFS=':' read -ra group <<< "$(getent group ${DOCKER_GID})"
  if [ -n "$group" ]; then
    addgroup jenkins $group
  else
    addgroup -g "${DOCKER_GID}" docker
    addgroup jenkins docker
  fi
fi