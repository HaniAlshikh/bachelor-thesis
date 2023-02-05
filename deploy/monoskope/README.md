# deploy

Deploy Monoskope to a local cluster.

The [deploy](deploy.mk) makefile will:

1. take care of the preparation work
2. create local `kind` cluster
3. add m8 dependencies to `helm`
4. setup and deploy m8 and it's dependencies

## Prerequisites

### Required

* [make](https://www.gnu.org/software/make/#download) to run deployment scripts
* [kind](https://kind.sigs.k8s.io/docs/user/quick-start/#installation) to create a local k9s cluster
* [helm](https://helm.sh/docs/intro/install/) to generate resource definitions
* [step-cli](https://smallstep.com/docs/step-cli/installation) to generate m8 PKI's trust-anchor

## Local development

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