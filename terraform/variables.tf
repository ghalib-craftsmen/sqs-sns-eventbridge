variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "ap-southeast-1"
}

variable "project_name" {
  description = "Prefix for all resource names and cost-allocation tag value"
  type        = string
  default     = "trainee-2026-abdullah-sqs-homework"
}

variable "admin_email" {
  description = "Email that receives bad messages and DLQ alerts"
  type        = string
}
