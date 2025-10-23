#!/bin/bash
set -e

# Detect distro, ubuntu or rhel supported
DISTRO=$( cat /etc/os-release | tr [:upper:] [:lower:] | grep -Poi '(ubuntu|rhel)' | uniq )

# Cleanup cloud-init and machine-id, this is generally only needed for non-AWS environments
if command -v cloud-init >/dev/null 2>&1; then
  cloud-init clean
fi
if [[ $DISTRO == "rhel" ]]; then
  truncate -s 0 /etc/machine-id
elif [[ $DISTRO == "ubuntu" ]]; then
  if command -v cloud-init >/dev/null 2>&1; then
    cloud-init clean --machine-id
  else
    truncate -s 0 /etc/machine-id
  fi
fi