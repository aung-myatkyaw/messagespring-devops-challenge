# Shared TFLint configuration for every root and module under infra/.

config {
  # Also lint our own modules where a root calls them.
  call_module_type = "local"
}

plugin "terraform" {
  enabled = true
  preset  = "recommended"
}

plugin "aws" {
  enabled = true
  version = "0.49.0"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}

# Every variable and output must say what it is for.
rule "terraform_documented_variables" {
  enabled = true
}

rule "terraform_documented_outputs" {
  enabled = true
}

rule "terraform_standard_module_structure" {
  enabled = true
}
