# deploy

Deploy Monoskope to a local cluster.

The [deploy](deploy.mk) makefile will:

1. take care of the preparation work
2. create local `kind` cluster
3. add m8 dependencies to `helm`
4. setup and deploy m8 and it's dependencies

## Prerequisites

### Required

A supported system from the following:

- MacOS
- Linux (tested on ubuntu)
- Windows (WSL)

Standard userspace utilities like `bash`, `curl`, `sh`, etc.... You can always change to alternatives by setting the corresponding environment variable. For example replacing `curl` with `wget` will be as follows:

```bash
CURL=wget make deploy
```

And the following tools

* [docker](https://docs.docker.com/get-docker/) to create isolated environments
* [make](https://www.gnu.org/software/make/#download) to run deployment scripts

Basic bundled utilities, like  etc... that are normally shipped with the following and 

### Automated

the following will be downloaded locally. If any should fail please the same as the curl example above applies.

* [kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl) to manage Kubernetes (k8s) resources
* [kind](https://kind.sigs.k8s.io/docs/user/quick-start/#installation) to create a local k9s cluster
* [helm](https://helm.sh/docs/intro/install/) to generate resource definitions
* [step-cli](https://smallstep.com/docs/step-cli/installation) to generate m8 PKI's trust-anchor

## Deployment

> **_IMPORTENTE:_**  When adapting the [setup files](setup) make sure to do a wide search and replace all occurrences if applicable

1. Deploy to the cluster with:

    ```shell
    make deploy
    ```

2. Trust m8 domain certificate: `tmp/domain-ca.crt`

    ```shell
    # MacOS
    sudo security add-trusted-cert -d -r trustRoot -k "/Library/Keychains/System.keychain" tmp/domain-ca.crt
    ```

3. Create port-forwards to the m8 API and DEX with:

    ```shell
    make port-forward
    ```

4. Add the following to your hostsfile:

    ```shell
    127.0.0.1 api.monoskope.dev
    127.0.0.1 dex
    ```

## Makefile

```
Usage:
  make <target>

General
  help             Display this help.

Helm
  helm-repo        add finleap-connect chart repo
  deploy           deploy monoskope
  template         template chart
  port-forward     create a port-forward to the m8 api and dex
```