#!/bin/bash
set -e

# Detect distro, ubuntu or rhel supported
DISTRO=$( cat /etc/os-release | tr [:upper:] [:lower:] | grep -Poi '(ubuntu|rhel)' | uniq )

# Install dependencies and cli tools needed by other packer scripts
if [[ $DISTRO == "rhel" ]]; then
  # Determine which stigs to apply based on RHEL version
  VERSION=$( cat /etc/os-release | grep -Poi '^version="[0-9]+\.[0-9]+' | cut -d\" -f2 | cut -d. -f1 )

  dnf update -y && dnf upgrade -y
  dnf install -y tar gzip zstd unzip nfs-utils nfs4-acl-tools lvm2 iscsi-initiator-utils curl cloud-init

  # Install Ansible
  # Note: Latest versions of ansible are not available in RHEL 9 repos, need to use pip
  dnf install python3.11 python3.11-pip -y
  python3.11 -m pip install --upgrade ansible

  # Temporarily add /usr/local/bin to PATH to ensure ansible is available
  export PATH=$PATH:/usr/local/bin

  #  Install rke2 selinux policy
  if [[ ${VERSION} -eq 9 ]] ; then
    curl -LO "https://github.com/rancher/rke2-selinux/releases/download/v0.18.stable.1/rke2-selinux-0.18-1.el9.noarch.rpm"
    dnf install rke2-selinux-0.18-1.el9.noarch.rpm -y
  else
    echo "Unrecognized RHEL version, exiting"
    exit 1
  fi
elif [[ $DISTRO == "ubuntu" ]]; then
  echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections
  apt-add-repository ppa:ansible/ansible -y
  apt-get update -y && apt-get upgrade -y
  apt-get install ansible unzip jq cloud-init -y
  # Install lvm2 for storage (e.x. rook/ceph)
  apt-get install lvm2 -y
  # Keep CA Certs up to date
  update-ca-certificates
fi

# Ensure that ansible collections needed are installed 
ansible-galaxy collection install community.general
ansible-galaxy collection install ansible.posix
