provider "aws" {
  region = "us-west-2"  # Adjust the region as necessary
}

data "aws_ami" "eks" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amazon-eks-node-*-v*"]
  }

  filter {
    name   = "owner-id"
    values = ["602401143452"]  # AWS EKS AMI account ID
  }

  filter {
    name   = "state"
    values = ["available"]
  }

  owners = ["602401143452"]  # AWS EKS AMI account ID
}

output "eks_optimized_ami_id" {
  value = data.aws_ami.eks.id
}