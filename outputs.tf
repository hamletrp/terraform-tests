output "eks_role_arn" {
  value = aws_iam_role.cluster_autoscaler_role.arn
}
