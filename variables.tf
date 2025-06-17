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

variable "environment" {
  type    = string
  default = "staging"
}

variable "nodegroup_name" {
  type    = string
  default = "linux-nodes"
}
variable "cluster_name" {
  type = string
}

variable "terraform_s3_bucket_name" {
  type    = string
  default = "terraform-state-bucket-3cbash"
}

variable "terraform_dynamodb_table_name" {
  type    = string
  default = "terraform-locks"
}

variable "managed_node_group_name" {
  type    = string
}

variable "test_site_zone_id" {
  type    = string
  default = "Z09059223NU9ETJKGVT4I"  # Replace with your Hosted Zone ID
}

variable "test_site_domain_name" {
  type    = string
}

variable "istio_nlb_dns_name" {
  type    = string
}

variable "istio_nlb_dns_zone_id" {
  type    = string
}

variable "cluster_13_vpc_id" {
  type    = string
}

variable "cluster_13_vpc_cidr" {
  type    = string
}

variable "cluster_13_routetable_id" {
  type    = string
}

variable "cluster_14_vpc_id" {
  type    = string
}

variable "cluster_14_vpc_cidr" {
  type    = string
}


variable "cluster_14_routetable_id" {
  type    = string
}



