locals {
  common_tags = {
    # terraform_creation_time = time_static.main["enabled"].rfc3339
    # terraform_module_name = "globomantics"
    company      = var.company_name,
    project      = "${var.company_name}-${var.project_name}"
    billing_code = var.billing_code
    environment  = var.environment
  }

  website_contents_base_folder = "website"

  naming_prefix = "${var.naming_prefix}-${var.environment}"

  s3_bucket_name = lower("${local.naming_prefix}-${random_integer.s3.result}")
}

resource "random_integer" "s3" {
  min = 10000
  max = 99999
}
