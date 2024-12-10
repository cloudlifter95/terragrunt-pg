# Indicate where to source the terraform module from.
# The URL used here is a shorthand for
# "tfr://registry.terraform.io/terraform-aws-modules/vpc/aws?version=5.8.1".
# Note the extra `/` after the protocol is required for the shorthand
# notation.
terraform {
  source = "tfr:///terraform-aws-modules/sqs/aws?version=4.2.1"
}

include "root" {
  path = find_in_parent_folders("provider.hcl")
}

include "root" {
  path = find_in_parent_folders("global.hcl")
}

locals {
  common_vars = read_terragrunt_config(find_in_parent_folders("common.hcl"))
}

# dependencies {
#   paths = ["${get_terragrunt_dir()}/random_pet"]
# }

# dependency doc under: https://terragrunt.gruntwork.io/docs/reference/config-blocks-and-attributes/#dependencies
dependency "random_pet" {
  config_path = "${get_terragrunt_dir()}/random_pet"
  skip_outputs = false
  # # Configure mock outputs for the `validate` command that are returned when there are no outputs available (e.g the
  # # module hasn't been applied yet.
  # mock_outputs_allowed_terraform_commands = ["apply", "plan", "validate"]
  # mock_outputs = {
  #  random_string = "random"
  # }
}

# Indicate the input values to use for the variables of the module.
inputs = {
  name = dependency.random_pet.outputs.random_string
  

  tags = {
    IAC = "true"
    Environment = "dev"
    Account = "account2"
    globaltag = local.common_vars.inputs.global_tag_value
  }
}