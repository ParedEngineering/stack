#!/bin/bash
set -e

export DEBIAN_FRONTEND=noninteractive
# This doesnt' truly disable apt-daily on boot, solution at bottom necessary
systemctl disable apt-daily.service
systemctl disable apt-daily.timer

apt-get update -y
apt-get upgrade -y

apt-get install -y \
        build-essential  \
        git \
        wget \
        dkms \
        apt-transport-https \
        ca-certificates \
        python-apt \
        python-pip \
        curl \
        netcat \
        ngrep \
        dstat \
        nmon \
        iptraf \
        iftop \
        iotop \
        atop \
        mtr \
        tree \
        unzip \
        sysdig \
        git \
        htop \
        jq \
        ntp \
        logrotate \
        dhcping \
        nfs-common \
        curl \
        unzip \
        jq \
        dhcpdump

pip install awscli

apt-get dist-upgrade -y

# We are failing to execute dpkg due to periodic updates of apt
# Issue referenced here https://bugs.launchpad.net/cloud-init/+bug/1693361
cat <<EOF >/etc/apt/apt.conf.d/10disable-periodic
APT::Periodic::Enable "0";
EOF