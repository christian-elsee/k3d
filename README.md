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
``` 

## Usage


## License

[MIT](https://choosealicense.com/licenses/mit/)
