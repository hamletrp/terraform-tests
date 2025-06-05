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

output "eks_cni_role_arn" {
  value = aws_iam_role.eks_cni_role.arn
}

output "aws_lb_controller_role_arn" {
  value = aws_iam_role.aws_lb_controller_role.arn
}

output "eso_irsa_role_arn" {
  value = aws_iam_role.eso_irsa_role.arn
}

output "karpenter_controller_role_arn" {
  value = aws_iam_role.karpenter_controller_role.arn
}

output "karpenter_interruption_queue_arn" {
  value = aws_sqs_queue.karpenter_interruption_queue.arn
}

output "karpenter_nodes_role_arn" {
  value = aws_iam_role.karpenter_nodes_role.arn
}

# output "eks_vpc_id" {
#   description = "The ID of the VPC"
#   value       = aws_vpc.eks_vpc1.id
# }

# output "eks_private_subnet_ids" {
#   description = "List of private subnet IDs with their AZs"
#   value = [
#     for subnet in aws_subnet.eks_subnet_private1 : {
#       id = subnet.id
#       az = subnet.availability_zone
#     }
#   ]
# }

# output "eks_public_subnet_ids" {
#   description = "List of private subnet IDs with their AZs"
#   value = [
#     for subnet in aws_subnet.eks_subnet_public1 : {
#       id = subnet.id
#       az = subnet.availability_zone
#     }
#   ]
# }

# output "eks_cluster_sg_id" {
#   description = "The ID of the cluster sg"
#   value       = aws_security_group.eks_cluster_sg.id
# }

# output "eks_node_sg_id" {
#   description = "The ID of the ndes sg"
#   value       = aws_security_group.eks_node_sg.id
# }

