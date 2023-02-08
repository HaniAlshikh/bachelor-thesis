#!/usr/bin/env bash

set -euo pipefail

echo "Forwarding m8 API at 8443..."
kubectl --kubeconfig $KUBECONFIG -n emissary port-forward svc/ei-emissary-ingress 8443:443 &
echo "Forwarding dex API at 5556..."
kubectl --kubeconfig $KUBECONFIG -n monoskope port-forward svc/dex 5556 &

wait