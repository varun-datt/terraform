provider "aws" {
  region = var.aws_region
  # credentials through AWS environment variables

  # https://registry.terraform.io/providers/hashicorp/aws/latest/docs/guides/resource-tagging
  default_tags {
    tags = {
      terraform = true
      # owner, company, project, billing_code, terraform repo etc.
    }
  }
}

# Multiple providers: https://www.terraform.io/docs/language/providers/configuration.html#alias-multiple-provider-configurations
# provider "aws" {
#   alias  = "alt-tags"
#   region = "us-west-1"
# }

provider "random" {} # optional since there's nothing to configure
