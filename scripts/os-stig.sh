#!/bin/bash
set -e

# Detect distro, rhel supported
DISTRO=$( cat /etc/os-release | tr [:upper:] [:lower:] | grep -Poi '(rhel)' | uniq )
VERSION=$( cat /etc/os-release | grep -Poi '^version="[0-9]+\.[0-9]+' | cut -d\" -f2 | cut -d. -f1 )

# Pull Ansible STIGs from https://public.cyber.mil/stigs/supplemental-automation-content/
mkdir -p /tmp/ansible && chmod 700 /tmp/ansible && cd /tmp/ansible
if [[ $DISTRO == "rhel" ]]; then
  # Temporarily add /usr/local/bin to PATH to ensure ansible is available as it is installed via pip
  export PATH=$PATH:/usr/local/bin

  # Determine which stigs to apply based on RHEL version
  if [[ ${VERSION} -eq 9 ]] ; then
    curl -L -o ansible.zip https://dl.dod.cyber.mil/wp-content/uploads/stigs/zip/U_RHEL_9_V2R4_STIG_Ansible.zip
  else
    echo "Unrecognized RHEL version, exiting"
    exit 1
  fi
fi
unzip ansible.zip
unzip *-ansible.zip

# Remove do_reboot handler from tasks file - VMs used to create templates from packer will be booted later for SELINUX changes to take effect
TASKS_FILE=$( find roles/*/tasks -name main.yml -type f )
sed -i '/notify: do_reboot/d' $TASKS_FILE

chmod +x enforce.sh && ./enforce.sh
