# deploy

Deploy Monoskope and MonoGUI to a local cluster.

The [deploy](deploy.mk) makefile will:

1. take care of the preparation work and installing the automated~
2. create local k8s cluster using `kind`
3. setup and deploy all needed resources

All while making sure to stay idempotent and localized.

## Prerequisites

### Required

- A supported system from the following:

  - MacOS
  - Linux (tested on Ubuntu)
  - Windows (WSL should work but not tested)

  For a sandboxed run [VirtualBox](https://www.virtualbox.org/) and [Ubuntu](https://www.linuxvmimages.com/images/ubuntu-2004/) can be used. Providers like [LinuxVMImages](https://www.linuxvmimages.com/) offer a ready to boot images, that runs with zero installation and configuration efforts.

  Standard userspace utilities like `bash`, `curl`, `sh`, etc.... should be available natively but can always be changed to alternatives by setting the corresponding environment variable. For example replacing curl with wget will be as  follows:

  ```shell
  $ CURL=wget make deploy
  ```

- The following tools

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

1. Create a local cluster and deploy all resources

    ```shell
    $ make deploy
    # you can also run the following 
    # to monitor the state of the resources
    $ make kind-watch
    ```

2. Trust m8 CA: `tmp/ca.crt`, otherwise the browser will block communication with m8 API

    ```shell
    # Linux/Ubuntu
    # Please add the CA
    # to the browser specific store
    # usually under advanced settings -> ceritifcates
    # MacOS
    # the following works for chrome and safari. 
    # Firefox manages its owen store. Please add manually
    $ make trust-m8-ca
    ```

3. Add the following to your hosts file:

    ```shell
    # Linux & MacOS: /etc/hosts
    # Windows: c:\Windows\System32\Drivers\etc\hosts
    127.0.0.1 api.monoskope.dev
    127.0.0.1 dex
    ```

4. Create port-forwards to route local request to backing services in the cluster: (Make sure `8443`, `5556` and `3000` are not in use)

    ```shell
    $ make port-forward
    ```

5. navigate to [http://localhost:3000](http://localhost:3000) and sign in using the following codeinitials:

    ```yaml
    username: admin@monoskope.dev
    password: password
    ```

6. Populate the EventStore with some mock data for a better user experience

    ```shell
    $ make mock-data
    ```

## Makefile

```shell
Usage:
  make <target>

General
  help             Display this help.

Manage
  kind-watch       watch monoskope beain deployed
  port-forward     create a port-forward to the m8Api, dex and monogui
  mock-data        create some aggregates in monoskope to enrich UX
  trust-m8-ca      trust monoskope certificate authority (OSX only)

Deploy
  deploy           deploy monoskope and monogui
  kind-create-cluster  create kind cluster
  deploy-m8-trust-anchor  create trust-anchor in kind cluster
  deploy-cert-manager  deploy dex
  deploy-emissary-ingress  deploy emissary-ingress
  deploy-dex       deploy dex
  deploy-monoskope  deploy monoskope
  deploy-monogui   deploy monoskope
  deploy-cleanup   uninstall everything again

Build Dependencies
  kubectl          Download kubectl locally if necessary.
  kind             Download kind locally if necessary.
  step             Download step locally if necessary.
  monoctl          Download monoctl locally if necessary.
  helm             Download helm locally if necessary.
  helm-repo        add necessary chart repos
```
