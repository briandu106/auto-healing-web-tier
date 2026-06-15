variable "aws_region" {
  type    = string
  default = "ap-southeast-4" # Default to Melbourne
}

variable "prefix" {
  type    = string
  default = "auto-healing-web-tier"
}

variable "tags" {
  type = map(string)
  default = {
    Environment = "Assessment"
    Owner       = "briandu106"
    ManagedBy   = "Terraform"
  }
}
