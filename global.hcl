## globals
# global backend configuration
terraform {
  before_hook "before_hook" {
    commands     = ["init", "apply", "plan"]
    execute      = ["echo", "Running Terragrunt"]
  }

  before_hook "before_hook" {
    commands     = ["init", "apply", "plan"]
    execute      = ["aws", "sts", "get-caller-identity"]
  }

  before_hook "before_hook" {
    commands     = ["init", "apply", "plan"]
    execute      = ["echo", "${local.common_vars.inputs.global_tag_value}"]
    run_on_error = true
  }

  after_hook "after_hook" {
    commands     = ["init", "apply", "plan"]
    execute      = ["echo", "Finished running Terragrunt"]
    run_on_error = true
  }
  after_hook "after_hook" {
    commands     = ["init", "apply", "plan"]
    execute      = ["echo", "${local.common_vars.inputs.global_tag_value}"]
    run_on_error = true
  }
}

locals {
  common_vars = read_terragrunt_config("${get_parent_terragrunt_dir()}/common.hcl")
}

# remote_state {
#   backend = "s3"
#   generate = {
#     path      = "backend.tf"
#     if_exists = "overwrite_terragrunt"
#   }
#   config = {
#     bucket = local.common_vars.inputs.backend_bucket_name

#     key = "${path_relative_to_include()}/terraform.tfstate"
#     region         = "us-east-1"
#     encrypt        = true
#     dynamodb_table = "my-lock-table"
#   }
# }