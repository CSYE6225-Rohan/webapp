#!/bin/bash

#Now switching to normal terminal and copying zip file to opt/csye6225 in ubuntu
# shellcheck disable=SC1091
source .env
# shellcheck disable=SC2154
ssh -i "$ssh_key" "$username"@"$ubuntu_ip"
