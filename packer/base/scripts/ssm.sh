#!/bin/bash
set -e

export DEBIAN_FRONTEND=noninteractive

cd /tmp
wget https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/debian_amd64/amazon-ssm-agent.deb
dpkg -i /tmp/amazon-ssm-agent.deb
systemctl enable amazon-ssm-agent
rm /tmp/amazon-ssm-agent.deb

