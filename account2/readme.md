# Minimal readme

Disclaimer: This was intended as a private experimentation of the terragrunt technology. This is not intended for production use.

## folder structure
```
.
├── account1
│   └── queue
├── account2
│   ├── provider.hcl
│   ├── queue
│   │   ├── random_pet
│   │   │   ├── main.tf
│   │   │   ├── outputs.tf
│   │   │   ├── terraform.tfstate
│   │   │   ├── terraform.tfstate.backup
│   │   │   └── terragrunt.hcl
│   │   └── terragrunt.hcl
│   └── readme.md
├── common.hcl
└── global.hcl
```

We will focus on account2/ folder.

## usage
Make sure to change `account2/provider.hcl` file with your specific provider details.

Navigate to account2/queue and run terragrunt  
`cd account2/queue && terragrunt apply`

## Problem statement
Although a dependency is defined between the module `account2/queue` and a random string generator module under `account2/queue/random_pet`, the `random_pet` module is not executed on apply (`cd account2/queue && terragrunt apply`).

Mocking the output on apply is the only workaround I found to unblock the provisioning:
```
mock_outputs_allowed_terraform_commands = ["apply", "plan", "validate"]
  mock_outputs = {
   random_string = "random"
  }
```
However, removing the mock results in the same initial error:
``` bash
10:57:56.609 ERROR  ./random_pet/terragrunt.hcl is a dependency of ./terragrunt.hcl but detected no outputs. Either the target module has not been applied yet, or the module has no outputs. If this is expected, set the skip_outputs flag to true on the dependency block.
10:57:56.609 ERROR  Unable to determine underlying exit code, so Terragrunt will exit with error code 1
```

Explicitely running a terraform apply of the random_pet module (ie: the dependency) seem to work. However, i would expect terragrunt to add it in the plan DAG on its own! See below. 

Steps (initial provisioning):
``` bash
cd account2/queue/random_pet && terraform init && terraform apply -auto-approve
cd ../ && terragrunt apply
```

However, keep in mind `random_pet` is used as a way to mimic a dynamic infrastructure, with a random string being generated on every apply.
In this case, unless I explictely re-run the random_pet module (`cd account2/queue/random_pet && terraform init && terraform apply -auto-approve`), terragrunt DOES NOT execute a run of the dependency.


Steps:
- Following an initial successful provisioning (see steps above), re-run a terragrunt apply WITHOUT explicitely running the dependency, notice the output shows "**no changes**":
    ``` bash
    cd account2/queue/ && terragrunt apply
    ```
- To confirm suspected bug, explicitely run the dependency then terragrunt apply on the parent module again** and notice the expected change this time**:
    ``` bash
    cd account2/queue/random_pet && terraform init && terraform apply -auto-approve
    cd ../ && terragrunt apply
    ```