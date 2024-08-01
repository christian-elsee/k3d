# k3d

A kubernetes k3d orchestration workflow.

- [Requirements](#requirements)
- [Setup](#setup)
- [Usage](#usage)
- [License](#license)

## Requirements

A list of development environment dependencies.  

- [GNU coreutils](https://en.wikipedia.org/wiki/List_of_GNU_Core_Utilities_commands), 9.5
```sh
$ brew info coreutils
==> coreutils: stable 9.5, HEAD
GNU File, Shell, and Text utilities
https://www.gnu.org/software/coreutils
...
```

- make, GNU Make 4.4.1
```sh
$ make --version
GNU Make 4.4.1
```

- kubectl, v1.30.0
```sh
$ kubectl version --client
Client Version: v1.30.0
Kustomize Version: v5.0.4-0.20230601165947-6ce0bf390ce3
```

## Setup

Idempotent setup of preliminary dependencies. 

Run setup workflow

```sh
$ make init
: ## assets/.touch
dirname assets/.touch | xargs mkdir -p
touch   assets/.touch
# iterate assets.yaml and install any missing assets
...
```

Ensure setup workflow is idempotent

```sh
$ make init
make: Nothing to be done for 'init'.
```

Workflow rebuilds can be triggered by updating setup dependencies. 
```sh
$ <Makefile grep -- '/.touch:' | awk '{ print $2 }'
assets.yaml
```
```sh
$ make init
make: Nothing to be done for 'init'.
$ touch assets.yaml
$ make init
: ## assets/.touch
dirname assets/.touch | xargs mkdir -p
touch   assets/.touch
# iterate assets.yaml and install any missing assets
...
``` 

## Usage

An overview of orchestration workflow. 

- [Create cluster](#create-cluster)
- [Manage kubeconfig](#manage-kubeconfig)
- [Delete cluster](#delete-cluser)

#### Create cluster

Create cluster using standard `make` workflow. 

```sh
$ make 
: ## distclean
rm -rf dist
: ## dist
...
```
```sh
$ make install
: ## install/cluster
# create cluster
k3d cluster create \
  --config config.yaml \
  --verbose
DEBU[0000] DOCKER_SOCK=/var/run/docker.sock   
...
```

Confirm cluster k3s containers exist

```sh
$ docker ps | grep lab1
d1e33342e78d        ghcr.io/k3d-io/k3d-proxy:5.7.2   "/bin/sh -c nginx-pr…"   2 minutes ago       Up About a minute   80/tcp, 0.0.0.0:52772->6443/tcp   k3d-lab1-serverlb
...
```

#### Manage kubeconfig

Cluster kubeconfig is written to `dist/kubeconfig` when `make install` workflow succeeds. The  workflow includes `kubectl` validation checks, similar to the following and can be reviewed in `dist/cluster-info*`.

```sh
$ kubectl --kubeconfig dist/kubeconfig cluster-info
Kubernetes control plane is running at https://lab1:51970
```

Management of kubeconfig is left to the operator, as it falls outside of the purview of the orchestration workflow and thus the intent of repository. A few common cases are detailed below, as a form of reference. 

- Copy kubeconfig to default path
```sh
$ cp -f dist/kubeconfig "$PWD/.kube/config"
$ kubectl cluster-info
Kubernetes control plane is running at https://lab1:51970
```

- Set `KUBECONFIG` env
```sh
$ rm -rf ~/.kube/config
$ kubectl cluster-info
E0801 13:58:51.775142   15183 memcache.go:265] couldn't get current server API group list: Get "http://localhost:8080/api?timeout=32s": dial tcp [::1]:8080: connect: connection refused
...
```
```sh
$ KUBECONFIG=$PWD/dist/kubeconfig kubectl cluster-info
Kubernetes control plane is running at https://lab1:51970
```

- Use `--kubeconfig` flag
```sh
$ kubectl --kubeconfig dist/kubeconfig cluster-info
Kubernetes control plane is running at https://lab1:51970
```

#### Delete cluster

Delete cluster using standard `make` workflow

```sh
$ make clean
: ## delete
<config.yaml yq -re ".metadata.name" \
  | xargs k3d cluster delete
INFO[0000] Deleting cluster 'lab1'                      
INFO[0003] Deleting cluster network 'k3d-lab1'          
INFO[0003] Deleting 1 attached volumes...               
INFO[0003] Removing cluster details from default kubeconfig... 
INFO[0003] Removing standalone kubeconfig file (if there is one)... 
INFO[0003] Successfully deleted cluster lab1!           
: ## distclean
rm -rf dist
```

Confirm k3s containers are destroyed

```sh
$ docker ps | grep -c lab1
0
```
## License

[MIT](https://choosealicense.com/licenses/mit/)
