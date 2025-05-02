variable "eks_role_name" {
  type    = string
  default = "eks-cluster-autoscaler-role"
}

variable "AWS_ACC_ID" {
  type    = string
  default = "722249351142"
}

variable "oidc_provider" {
  type    = string
  default = "oidc.eks.us-east-1.amazonaws.com/id/DC1A7CD17A3AF9F88667AE58F1EF2A03"
}