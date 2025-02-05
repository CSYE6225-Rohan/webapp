#!/bin/bash

# shellcheck disable=SC1091
source .env

# shellcheck disable=SC2154
scp -i "$ssh_key" "$path_of_zip" "$username"@"$ubuntu_ip":/opt

# shellcheck disable=SC2154
scp -i "$ssh_key" "$path_of_ubuntu_env" "$username"@"$ubuntu_ip":/opt

# shellcheck disable=SC2154
scp -i "$ssh_key" "$path_of_ubuntu_sh" "$username"@"$ubuntu_ip":/opt

ssh -i "$ssh_key" "$username"@"$ubuntu_ip" <<EOF
    chmod +x /opt/ubuntu.sh
EOF