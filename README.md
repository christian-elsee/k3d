# k3d

A kubernetes k3d orchestration workflow.

- [Requirements](#requirements)
- [Setup](#setup)
- [Usage](#usage)
- [Testing](#testing)
- [KUBECONFIG](#testing)
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

## Setup

Idempotent setup of preliminary dependencies. 

```sh
$ make init
: ## assets
mkdir -p assets
# iterate assets.yaml and install any missing assets
...
```

## Usage

An overview of eks orchestration workflow.

1\. Create a [eksctl configuration](https://eksctl.io/usage/schema/) overlay. 
```sh
$ tee overlays/cache-stack.yaml <<eof 
---
metadata:
  name: cache-stack
  region: us-east-1
managedNodeGroups:
  - name: cache-stack-varnish
    privateNetworking: false
    instanceType: m5.large
    desiredCapacity: 3
    minSize: 1
    maxSize: 3
    labels:
      nodegroup: vache-stack-varnish

eof
```

2\. Generate a decarative configuration "plan". 
```sh
$ AWS_PROFILE=EKSAssumeRole \
  OVERLAYS=overlays/cache-stack.yaml \
  make 
...
Assume Role MFA token code:
```
```sh
$ <dist/plan.yaml head -n5
accessConfig:
  authenticationMode: API_AND_CONFIG_MAP
addonsConfig: {}
apiVersion: eksctl.io/v1alpha5
availabilityZones:
```

3\. Apply configuration "plan".
```sh
$ AWS_PROFILE=EKSAssumeRole make install
: ## install
eksctl create cluster \
        -f dist/plan.yaml \
        --kubeconfig dist/config \
        --write-kubeconfig=true
...
2024-06-24 12:43:56 [ℹ]  building cluster stack "eksctl-cache-stack-cluster"
2024-06-24 12:43:57 [ℹ]  deploying stack "eksctl-cache-stack-cluster"
...
  Version: "1.30"
a .
a ./plan.yaml
a ./get-cluster.yaml
a ./cluster.yaml
a ./checksum
```

4\. Verify that a cluster.tar.$checksum artifact has been published to assets.
```sh
$ tar -tvf assets/cluster.tar.$(cat dist/checksum | tee /dev/stderr )
d0a9189959d817a3ee52b6f6546a8861
drwxr-xr-x  0 christian staff       0 Jun 24 18:10 ./
-rw-r--r--  0 christian staff    1537 Jun 23 10:48 ./plan.yaml
-rw-r--r--  0 christian staff    3515 Jun 24 18:10 ./get-cluster.yaml
-rw-r--r--  0 christian staff     291 Jun 23 10:48 ./cluster.yaml
-rw-r--r--  0 christian staff      33 Jun 23 10:48 ./checksum
```

## Testing

[TAP complient](https://testanything.org) tests used to sanity check orchestration workflow.

1\. Run  test suite
```sh
$ make test
: ## test
prove -v
t/0-dogfood.t ..
ok 1 it should expect dog food
ok 2 it should consider dog food
ok 3 it should eat dog food
1..3
ok
t/10-smoke.t ..
ok 1 it should work with kubectl
1..1
ok
All tests successful.
Files=2, Tests=4, 22 wallclock secs ( 0.02 usr  0.02 sys +  0.24 cusr  0.14 csys =  0.42 CPU)
Result: PASS
```

## KUBECONFIG

An orchestrated eks cluster config is written to `dist/kubeconfig` and is published as an artifact to `assets/cluster.tar.$checksum`. If [smoke tests](#testing) succeed, then kubeconfig is valid.

The config file can be moved as is to your [KUBECONFIG](https://kubernetes.io/docs/concepts/configuration/organize-cluster-access-kubeconfig/) path. Additionally, you can merge with existing cluster configuration, as a new context.

1\. Review contexts defined in existing default cluster configuration
```sh
$ <~/.kube/config  yq -re '.contexts | map(.name)[]'
default

```

2\. Review context defined in EKS cluster configuration
```sh
$ <dist/kubeconfig  yq -re '.contexts | map(.name)[]'
cli@secrets-stack.eu-north-1.eksctl.io
```

3\. Merge contexts into a single configuration
```sh
$ KUBECONFIG=dist/kubeconfig:$HOME/.kube/config kubectl config view \
  --flatten \
| kubectl --kubeconfig /dev/stdin config get-contexts
CURRENT   NAME                                     CLUSTER                              AUTHINFO                                 NAMESPACE
*         cli@secrets-stack.eu-north-1.eksctl.io   secrets-stack.eu-north-1.eksctl.io   cli@secrets-stack.eu-north-1.eksctl.io
          default                                  default                              default
~/Develop/github.com/christian-elsee/eks

```

## License

[MIT](https://choosealicense.com/licenses/mit/)
