terraform {
  backend "s3" {
    bucket         = "terraform-state-bucket-3cbash"
    key            = "dev/terraform-eks-cluster-lab-1.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}