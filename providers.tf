provider "aws" {
  profile = "default"
  region  = "us-east-1"
}

provider "helm" {
  kubernetes = {
    config_path = "~/.kube/config"
    config_context = "hamletrp@cluster-lab-13.us-east-1.eksctl.io"
  }
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.67.0"
    }
  }
}
