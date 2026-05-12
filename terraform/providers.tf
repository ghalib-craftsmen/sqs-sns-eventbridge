terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.50"
    }
  }
}

provider "aws" {
  region = var.aws_region

  # Every resource gets tagged with the project name.
  # Activate `Project` as a cost-allocation tag in Billing → Cost Allocation Tags,
  # then filter by Project=<project_name> in Cost Explorer to see total cost.
  default_tags {
    tags = {
      Project   = var.project_name
      ManagedBy = "terraform"
    }
  }
}
