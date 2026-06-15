provider "aws" {
  region = var.aws_region

  # Force Terraform to evaluate the plan completely offline
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_metadata_api_check     = true
}

module "networking" {
  source = "./modules/networking"
  prefix = var.prefix
  tags   = var.tags
}

# Comment out for Terraform plan to proceed
# Fetch latest Ubuntu AMI
# data "aws_ami" "ubuntu" {
#  most_recent = true
#  filter {
#    name   = "name"
#    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
#  }
#  filter {
#    name   = "virtualization-type"
#    values = ["hvm"]
#  }
#  owners = ["099720109477"] # Canonical
#}

module "compute" {
  source         = "./modules/compute"
  prefix         = var.prefix
  vpc_id         = module.networking.vpc_id
  public_subnets = module.networking.public_subnet_ids
  ami_id         = "ami-mock1234567890" # Pass a sample string for the Terraform plan to proceed
  # ami_id           = data.aws_ami.ubuntu.id
  user_data_base64 = base64encode(file("${path.module}/templates/user_data.sh"))
  tags             = var.tags
}
