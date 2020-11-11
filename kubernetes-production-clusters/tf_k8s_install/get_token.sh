#!/usr/bin/env bash

set -e

# Extract input variables
eval "$(jq -r '@sh "HOST=\(.host) PRIVATE_KEY=\(.private_key)"')"

# Ask kubeadm on master to generate a fully formed join command, suitable for
# executing on each of the workers
JOIN_COMMAND=$(ssh   -o "StrictHostKeyChecking=no" appuser@$HOST sudo kubeadm token create --print-join-command)

# Return it in a JSON result
jq -n --arg command "$JOIN_COMMAND" '{"command":$command}'

