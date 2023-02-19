# deploy

Deploy Monoskope and MonoGUI to a local cluster.

The [deploy](deploy.mk) makefile will:

1. take care of the preparation work
2. create local Kubernetes cluster using `kind`
3. add Monoskope and MonoGUI dependencies to `helm`
4. setup and deploy all needed resources

All while making sure to stay idempotent and localized.

## Prerequisites

### Required

A supported system from the following:

- MacOS
- Linux (tested on ubuntu)
- Windows (WSL)

Standard userspace utilities like `bash`, `curl`, `sh`, etc.... You can always change to alternatives by setting the corresponding environment variable. For example replacing `curl` with `wget` will be as follows:

```shell
CURL=wget make deploy
```

And the following tools

- [docker](https://docs.docker.com/get-docker/) to create isolated environments
- [make](https://www.gnu.org/software/make/#download) to run deployment scripts

### Automated

the following will be downloaded and configured locally. If any should fail please follow the same instruction as the curl example above, when done downloading and installing manually.

- [kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl) to manage Kubernetes (k8s) resources
- [kind](https://kind.sigs.k8s.io/docs/user/quick-start/#installation) to create a local k9s cluster
- [helm](https://helm.sh/docs/intro/install/) to generate resource definitions
- [step-cli](https://smallstep.com/docs/step-cli/installation) to generate m8 PKI's trust-anchor

## Test Run

> **_IMPORTENTE:_*-  If you decided to make changes on the [setup files](setup) please make sure to do a wide search and replace all occurrences if applicable.

1. Deploy all resources to a local cluster:

    ```shell
    make deploy
    # you can also run the following to monitor the state of the resources
    make kind-watch
    ```

2. Trust m8 domain certificate: `tmp/domain-ca.crt`, otherwise the browser will block communication with m8 API

    ```shell
    # MacOS
    sudo security add-trusted-cert -d -r trustRoot -k "/Library/Keychains/System.keychain" tmp/domain-ca.crt
    ```

3. Add the following to your hosts file:

    ```shell
    127.0.0.1 api.monoskope.dev
    127.0.0.1 dex
    ```

4. Create port-forwards to route local request to backing services in the cluster: (Make sure `8443`, `5556` and `3000` are not in use)

    ```shell
    make port-forward
    ```

5. navigate to [http://localhost:3000](http://localhost:3000) and sign in using the following codeinitials:

    ```yaml
    username: admin@monoskope.dev
    password: password
    ```

6. Populate the EventStore with some mock data for a better user experience

    ```shell
    make mock-data
    ```

## Makefile

```shell
Usage:
  make <target>

General
  help                      Display this help.

Manage
  kind-watch                watch monoskope beain deployed
  port-forward              create a port-forward to the m8Api, dex and monogui
  mock-data                 restore mocked data into monoskope backing database

Deploy
  deploy                    deploy monoskope and monogui
  kind-create-cluster       create kind cluster
  deploy-m8-trust-anchor    create trust-anchor in kind cluster
  deploy-cert-manager       deploy dex
  deploy-emissary-ingress   deploy emissary-ingress
  deploy-dex                deploy dex
  deploy-monoskope          deploy monoskope
  deploy-monogui            deploy monoskope
  deploy-cleanup            uninstall everything again

Build Dependencies          
  kubectl                   Download kubectl locally if necessary.
  kind                      Download kind locally if necessary.
  step                      Download step locally if necessary.
  helm                      Download helm locally if necessary.
  helm-repo                 add necessary chart repos
```