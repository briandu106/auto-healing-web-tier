variable "prefix" {
  type        = string
  description = "Resource name prefix"
}

variable "vpc_id" {
  type        = string
  description = "The ID of the VPC where security groups will be created"
}

variable "public_subnets" {
  type        = list(string)
  description = "List of public subnet IDs for the ALB and ASG"
}

variable "ami_id" {
  type        = string
  description = "The AMI ID to use for the EC2 launch template"
}

variable "user_data_base64" {
  type        = string
  description = "Base64 encoded cloud-init user-data script"
}

variable "instance_type" {
  type        = string
  default     = "t3.micro"
  description = "EC2 instance size for the web tier"
}

variable "tags" {
  type        = map(string)
  description = "Global tags to apply to compute resources"
}
