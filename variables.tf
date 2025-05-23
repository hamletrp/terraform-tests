variable "eks_role_name" {
  type    = string
  default = "eks-cluster-autoscaler-role"
}

variable "AWS_REGION" {
  type    = string
  default = "us-east-1"
}

variable "AWS_ACC_ID" {
  type    = string
  default = "722249351142"
}

variable "oidc_provider" {
  type    = string
  default = ""
}

variable "oidc_provider_url" {
  type    = string
  default = ""
}

variable "nodegroup_name" {
  type    = string
  default = "linux-nodes"
}
variable "cluster_name" {
  type    = string
  default = "cluster-lab4"
}

variable "terraform_s3_bucket_name" {
  type    = string
  default = "terraform-state-bucket-3cbash"
}

variable "terraform_dynamodb_table_name" {
  type    = string
  default = "terraform-locks"
}

