#!/usr/bin/env bash

set -eu

echo "Forwarding m8 API at 8443..."
$KUBECTL --kubeconfig $KUBECONFIG -n emissary port-forward svc/ei-emissary-ingress 8443:443 &
echo "Forwarding dex API at 5556..."
$KUBECTL --kubeconfig $KUBECONFIG -n monoskope port-forward svc/dex 5556 &
echo "Forwarding monogui at 3000..."
$KUBECTL --kubeconfig $KUBECONFIG -n monoskope port-forward svc/monogui 3000:80 &

wait