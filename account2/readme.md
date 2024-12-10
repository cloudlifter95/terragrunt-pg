# Minimal readme

Disclaimer: This is intended as a private experimentation of the terragrunt technology. This is not intended for production use.

**2 problem statements are described within this readme.**

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

## Problem statement 1: "apply" attempting to get non-existent outputs.
Although a dependency is defined between the module `account2/queue` and a random string generator module under `account2/queue/random_pet`, the `random_pet` module is not executed on apply (`cd account2/queue && terragrunt apply`).

Mocking the output on apply is a workaround to unblock the provisioning:
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

## Problem statement 2: Run-all plan showing no change
An alternative is to also run the `run-all apply`/`apply-all` command.


- "apply-all" orchestrates and applies each dependency successfully, which aligns with the documentation: [Documentation](https://terragrunt.gruntwork.io/docs/getting-started/configuration/#:~:text=Note%20that%20the,all%20apply.)

- however, "plan-all" while building successfully the DAG, shows the outputs of the dependency to be "known after apply"(great!) but the dependent modules are shown to have "no change" (which is wrong). Mocking would not help either under the "plan-all"/"apply-all"/"run-all plan"/"run-all apply" commands.

In a nutshell, from where I stand i'd prefer the "plan-all"/"run-all plan" shows there are expected changes on those dependent modules instead of showing "no change". 

**Trace:**
``` bash
USER:~/Terraform/terragrunt/account2/queue (dev) $ tg plan-all
16:55:35.653 WARN   The `plan-all` command is deprecated and will be removed in a future version. Use `terragrunt run-all plan` instead.
16:55:35.666 INFO   The stack at . will be processed in the following order for command plan:
Group 1
- Module ./random_pet

Group 2
- Module .

16:55:35.985 STDOUT [random_pet] terraform: random_pet.this: Refreshing state... [id=jaybird]
16:55:35.990 STDOUT [random_pet] terraform: Terraform used the selected providers to generate the following execution
16:55:35.990 STDOUT [random_pet] terraform: plan. Resource actions are indicated with the following symbols:
16:55:35.990 STDOUT [random_pet] terraform: -/+ destroy and then create replacement
16:55:35.990 STDOUT [random_pet] terraform: Terraform will perform the following actions:
16:55:35.990 STDOUT [random_pet] terraform:   # random_pet.this must be replaced
16:55:35.990 STDOUT [random_pet] terraform: -/+ resource "random_pet" "this" {
16:55:35.990 STDOUT [random_pet] terraform:       ~ id        = "jaybird" -> (known after apply)
16:55:35.990 STDOUT [random_pet] terraform:       ~ keepers   = { # forces replacement
16:55:35.990 STDOUT [random_pet] terraform:           ~ "uuid" = "8ca1795e-bec3-3e58-51ea-7e37ca67e887" -> (known after apply)
16:55:35.990 STDOUT [random_pet] terraform:         }
16:55:35.990 STDOUT [random_pet] terraform:         # (2 unchanged attributes hidden)
16:55:35.990 STDOUT [random_pet] terraform:     }
16:55:35.990 STDOUT [random_pet] terraform: Plan: 1 to add, 0 to change, 1 to destroy.
16:55:35.990 STDOUT [random_pet] terraform:
16:55:35.990 STDOUT [random_pet] terraform: Changes to Outputs:
16:55:35.990 STDOUT [random_pet] terraform:   ~ random_string = "jaybird" -> (known after apply)
16:55:35.990 STDOUT [random_pet] terraform:
16:55:35.990 STDOUT [random_pet] terraform: ─────────────────────────────────────────────────────────────────────────────
16:55:35.991 STDOUT [random_pet] terraform: Note: You didn't use the -out option to save this plan, so Terraform can't
16:55:35.991 STDOUT [random_pet] terraform: guarantee to take exactly these actions if you run "terraform apply" now.
16:55:36.217 INFO   Executing hook: before_hook
16:55:36.221 INFO   Executing hook: before_hook
16:55:37.018 INFO   Executing hook: before_hook
16:55:39.707 STDOUT terraform: data.aws_region.current: Reading...
16:55:39.707 STDOUT terraform: data.aws_caller_identity.current: Reading...
16:55:39.708 STDOUT terraform: data.aws_region.current: Read complete after 0s [id=eu-central-1]
16:55:39.708 STDOUT terraform: aws_sqs_queue.this[0]: Refreshing state... [id=https://sqs.eu-central-1.amazonaws.com/****/jaybird]
16:55:39.735 STDOUT terraform: data.aws_caller_identity.current: Read complete after 0s [id=****]
16:55:40.180 STDOUT terraform: No changes. Your infrastructure matches the configuration.
16:55:40.180 STDOUT terraform: Terraform has compared your real infrastructure against your configuration
16:55:40.180 STDOUT terraform: and found no differences, so no changes are needed.
16:55:40.182 INFO   Executing hook: after_hook
16:55:40.185 INFO   Executing hook: after_hook
Running Terragrunt
{
    "UserId": "***",
    "Account": "****",
    "Arn": "arn:aws:iam::****:user/***"
}
testglobalinput
Finished running Terragrunt
testglobalinput
USER:~/Terraform/terragrunt/account2/queue (dev) $ tg apply-all
16:56:47.975 WARN   The `apply-all` command is deprecated and will be removed in a future version. Use `terragrunt run-all apply` instead.
16:56:48.002 INFO   The stack at . will be processed in the following order for command apply:
Group 1
- Module ./random_pet

Group 2
- Module .

Are you sure you want to run 'terragrunt apply' in each folder of the stack described above? (y/n) y
16:56:49.837 STDOUT [random_pet] terraform: random_pet.this: Refreshing state... [id=jaybird]
16:56:49.842 STDOUT [random_pet] terraform: Terraform used the selected providers to generate the following execution
16:56:49.842 STDOUT [random_pet] terraform: plan. Resource actions are indicated with the following symbols:
16:56:49.843 STDOUT [random_pet] terraform: -/+ destroy and then create replacement
16:56:49.843 STDOUT [random_pet] terraform: Terraform will perform the following actions:
16:56:49.843 STDOUT [random_pet] terraform:   # random_pet.this must be replaced
16:56:49.843 STDOUT [random_pet] terraform: -/+ resource "random_pet" "this" {
16:56:49.843 STDOUT [random_pet] terraform:       ~ id        = "jaybird" -> (known after apply)
16:56:49.843 STDOUT [random_pet] terraform:       ~ keepers   = { # forces replacement
16:56:49.843 STDOUT [random_pet] terraform:           ~ "uuid" = "8ca1795e-bec3-3e58-51ea-7e37ca67e887" -> (known after apply)
16:56:49.843 STDOUT [random_pet] terraform:         }
16:56:49.843 STDOUT [random_pet] terraform:         # (2 unchanged attributes hidden)
16:56:49.843 STDOUT [random_pet] terraform:     }
16:56:49.843 STDOUT [random_pet] terraform: Plan: 1 to add, 0 to change, 1 to destroy.
16:56:49.843 STDOUT [random_pet] terraform:
16:56:49.843 STDOUT [random_pet] terraform: Changes to Outputs:
16:56:49.843 STDOUT [random_pet] terraform:   ~ random_string = "jaybird" -> (known after apply)
16:56:49.885 STDOUT [random_pet] terraform: random_pet.this: Destroying... [id=jaybird]
16:56:49.887 STDOUT [random_pet] terraform: random_pet.this: Destruction complete after 0s
16:56:49.898 STDOUT [random_pet] terraform: random_pet.this: Creating...
16:56:49.898 STDOUT [random_pet] terraform: random_pet.this: Creation complete after 0s [id=hare]
16:56:49.912 STDOUT [random_pet] terraform:
16:56:49.912 STDOUT [random_pet] terraform: Apply complete! Resources: 1 added, 0 changed, 1 destroyed.
16:56:49.912 STDOUT [random_pet] terraform:
16:56:49.912 STDOUT [random_pet] terraform: Outputs:
16:56:49.912 STDOUT [random_pet] terraform: random_string = "hare"
16:56:51.084 INFO   Executing hook: before_hook
16:56:51.226 INFO   Executing hook: before_hook
16:56:53.348 INFO   Executing hook: before_hook
16:56:56.897 STDOUT terraform: data.aws_region.current: Reading...
16:56:56.897 STDOUT terraform: data.aws_caller_identity.current: Reading...
16:56:56.898 STDOUT terraform: aws_sqs_queue.this[0]: Refreshing state... [id=https://sqs.eu-central-1.amazonaws.com/****/jaybird]
16:56:56.899 STDOUT terraform: data.aws_region.current: Read complete after 0s [id=eu-central-1]
16:56:56.935 STDOUT terraform: data.aws_caller_identity.current: Read complete after 0s [id=****]
16:56:57.393 STDOUT terraform: Terraform used the selected providers to generate the following execution
16:56:57.393 STDOUT terraform: plan. Resource actions are indicated with the following symbols:
16:56:57.393 STDOUT terraform: -/+ destroy and then create replacement
16:56:57.393 STDOUT terraform: Terraform will perform the following actions:
16:56:57.393 STDOUT terraform:   # aws_sqs_queue.this[0] must be replaced
16:56:57.393 STDOUT terraform: -/+ resource "aws_sqs_queue" "this" {
16:56:57.393 STDOUT terraform:       ~ arn                               = "arn:aws:sqs:eu-central-1:****:jaybird" -> (known after apply)
16:56:57.393 STDOUT terraform:       + deduplication_scope               = (known after apply)
16:56:57.393 STDOUT terraform:       + fifo_throughput_limit             = (known after apply)
16:56:57.393 STDOUT terraform:       ~ id                                = "https://sqs.eu-central-1.amazonaws.com/****/jaybird" -> (known after apply)
16:56:57.393 STDOUT terraform:       ~ kms_data_key_reuse_period_seconds = 300 -> (known after apply)
16:56:57.394 STDOUT terraform:       ~ name                              = "jaybird" -> "hare" # forces replacement
16:56:57.394 STDOUT terraform:       + name_prefix                       = (known after apply)
16:56:57.394 STDOUT terraform:       + policy                            = (known after apply)
16:56:57.394 STDOUT terraform:       + redrive_allow_policy              = (known after apply)
16:56:57.394 STDOUT terraform:       + redrive_policy                    = (known after apply)
16:56:57.394 STDOUT terraform:         tags                              = {
16:56:57.394 STDOUT terraform:             "Account"     = "account2"
16:56:57.394 STDOUT terraform:             "Environment" = "dev"
16:56:57.394 STDOUT terraform:             "IAC"         = "true"
16:56:57.394 STDOUT terraform:             "globaltag"   = "testglobalinput"
16:56:57.394 STDOUT terraform:         }
16:56:57.394 STDOUT terraform:       ~ url                               = "https://sqs.eu-central-1.amazonaws.com/****/jaybird" -> (known after apply)
16:56:57.394 STDOUT terraform:         # (9 unchanged attributes hidden)
16:56:57.394 STDOUT terraform:     }
16:56:57.394 STDOUT terraform: Plan: 1 to add, 0 to change, 1 to destroy.
16:56:57.394 STDOUT terraform:
16:56:57.394 STDOUT terraform: Changes to Outputs:
16:56:57.395 STDOUT terraform:   ~ queue_arn                    = "arn:aws:sqs:eu-central-1:****:jaybird" -> (known after apply)
16:56:57.395 STDOUT terraform:   ~ queue_arn_static             = "arn:aws:sqs:eu-central-1:****:jaybird" -> "arn:aws:sqs:eu-central-1:****:hare"
16:56:57.395 STDOUT terraform:   ~ queue_id                     = "https://sqs.eu-central-1.amazonaws.com/****/jaybird" -> (known after apply)
16:56:57.395 STDOUT terraform:   ~ queue_name                   = "jaybird" -> "hare"
16:56:57.395 STDOUT terraform:   ~ queue_url                    = "https://sqs.eu-central-1.amazonaws.com/****/jaybird" -> (known after apply)
16:56:58.460 STDOUT terraform: aws_sqs_queue.this[0]: Destroying... [id=https://sqs.eu-central-1.amazonaws.com/****/jaybird]
16:57:00.719 STDOUT terraform: aws_sqs_queue.this[0]: Destruction complete after 3s
16:57:00.733 STDOUT terraform: aws_sqs_queue.this[0]: Creating...
16:57:10.736 STDOUT terraform: aws_sqs_queue.this[0]: Still creating... [10s elapsed]
16:57:20.737 STDOUT terraform: aws_sqs_queue.this[0]: Still creating... [20s elapsed]
16:57:26.186 STDOUT terraform: aws_sqs_queue.this[0]: Creation complete after 25s [id=https://sqs.eu-central-1.amazonaws.com/****/hare]
16:57:26.205 STDOUT terraform:
16:57:26.205 STDOUT terraform: Apply complete! Resources: 1 added, 0 changed, 1 destroyed.
16:57:26.205 STDOUT terraform:
16:57:26.205 STDOUT terraform: Outputs:
16:57:26.205 STDOUT terraform: dead_letter_queue_arn_static = ""
16:57:26.205 STDOUT terraform: queue_arn = "arn:aws:sqs:eu-central-1:****:hare"
16:57:26.206 STDOUT terraform: queue_arn_static = "arn:aws:sqs:eu-central-1:****:hare"
16:57:26.206 STDOUT terraform: queue_id = "https://sqs.eu-central-1.amazonaws.com/****/hare"
16:57:26.206 STDOUT terraform: queue_name = "hare"
16:57:26.206 STDOUT terraform: queue_url = "https://sqs.eu-central-1.amazonaws.com/****/hare"
16:57:26.210 INFO   Executing hook: after_hook
16:57:26.238 INFO   Executing hook: after_hook
Running Terragrunt
{
    "UserId": "***",
    "Account": "****",
    "Arn": "arn:aws:iam::****:user/***"
}
testglobalinput
Finished running Terragrunt
testglobalinput
USER:~/Terraform/terragrunt/account2/queue (dev) $
```