variable "prefix" {
  type        = string
  description = "Resource name prefix"
}

variable "tags" {
  type        = map(string)
  description = "Global tags to apply to networking resources"
}

variable "vpc_cidr" {
  type        = string
  default     = "10.0.0.0/16"
  description = "CIDR block for the VPC"
}

variable "availability_zones" {
  type        = list(string)
  default     = ["ap-southeast-4a", "ap-southeast-4b"] # Default regions for mapping
  description = "Static list of target AZs for offline planning"
}
