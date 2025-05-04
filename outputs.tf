output "eks_role_arn" {
  value = aws_iam_role.cluster_autoscaler_role.arn
}

output "eks_node_group_role_arn" {
  value = aws_iam_role.eks_node_group_role.arn
}

output "ebs_csi_driver_role_arn" {
  value = aws_iam_role.ebs_csi_driver_role.arn
}

output "eks_alb_controller_irsa_role_arn" {
  value = aws_iam_role.eks_alb_controller_irsa_role.arn
}
