provider "aws" {
  profile = "default"
  region  = "us-east-1"
}

resource "aws_iam_role" "cluster_autoscaler_role" {
  name = var.eks_role_name
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy_oidc_provider.json
}

resource "aws_iam_policy" "cluster_autoscaler_policy" {
  name        = "eks-cluster-autoscaler-policy"
  description = "Policy for EKS Cluster Autoscaler"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeAutoScalingInstances",
          "autoscaling:DescribeLaunchConfigurations",
          "autoscaling:DescribeTags",
          "autoscaling:SetDesiredCapacity",
          "autoscaling:TerminateInstanceInAutoScalingGroup",
          "ec2:DescribeLaunchTemplateVersions",
          "autoscaling:UpdateAutoScalingGroup"
        ],
        Resource = "*"
      }
      # ,{
      #   Effect = "Allow",
      #   Action = [
      #     "ec2:CreateVolume"
      #   ],
      #   Resource = " arn:aws:ec2:${var.AWS_REGION}:${var.AWS_ACC_ID}:volume/*"
      # }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_cluster_autoscaler_policy" {
  role       = aws_iam_role.cluster_autoscaler_role.name
  policy_arn = aws_iam_policy.cluster_autoscaler_policy.arn
}

resource "aws_iam_role" "eks_node_group_role" {
  name               = "eksctl-${var.cluster_name}-nodegroup-linu-NodeInstanceRole"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.eks_assume_role_policy.json

  tags = {
    "alpha.eksctl.io/nodegroup-name"                    = "${var.nodegroup_name}"
    "k8s.io/cluster-autoscaler/${var.cluster_name}"     = "owned"
    "environment"                                       = "staging"
    "alpha.eksctl.io/cluster-name"                      = "${var.cluster_name}"
    "eksctl.cluster.k8s.io/v1alpha1/cluster-name"       = "${var.cluster_name}"
    "alpha.eksctl.io/nodegroup-type"                    = "managed"
    "team"                                              = "platform"
    "k8s.io/cluster-autoscaler/enabled"                = "true"
    "alpha.eksctl.io/eksctl-version"                    = "0.207.0"
    "Name"                                              = "eksctl-${var.cluster_name}-nodegroup-linux-nodes3/NodeInstanceRole"
  }
} 

# Attach Required AWS Managed Policies
resource "aws_iam_role_policy_attachment" "AmazonEKSWorkerNodePolicy" {
  role       = aws_iam_role.eks_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy" {
  role       = aws_iam_role.eks_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly" {
  role       = aws_iam_role.eks_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "AmazonSSMManagedInstanceCore" {
  role       = aws_iam_role.eks_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_policy" "eks_node_group_role_inline_policy" {
  name        = "eks-cluster-autoscaler-inline-policy"
  description = "Policy for EKS ece instance nodes role"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ec2:CreateVolume",
          "ec2:CreateTags",
          "ec2:AttachVolume",
          "ec2:DetachVolume",
          "ec2:DeleteVolume"
        ],
        Resource = [
          "arn:aws:ec2:${var.AWS_REGION}:${var.AWS_ACC_ID}:volume/",
          "arn:aws:ec2:${var.AWS_REGION}:${var.AWS_ACC_ID}:volume/*",
          "arn:aws:ec2:${var.AWS_REGION}:${var.AWS_ACC_ID}:instance/",
          "arn:aws:ec2:${var.AWS_REGION}:${var.AWS_ACC_ID}:instance/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_eks_node_group_role_inline_policy" {
  role       = aws_iam_role.eks_node_group_role.name
  policy_arn = aws_iam_policy.eks_node_group_role_inline_policy.arn
}


# IAM Role for EBS CSI driver with trust relationship to EKS OIDC provider
resource "aws_iam_role" "ebs_csi_driver_role" {
  name = "AmazonEKS_EBS_CSI_DriverRole"

  assume_role_policy = data.aws_iam_policy_document.assume_role_policy_oidc_provider.json

  tags = {
    "eksctl.cluster.k8s.io/v1alpha1/cluster-name" = var.cluster_name
    "kubernetes.io/cluster/${var.cluster_name}"   = "owned"
    "k8s.io/cluster-autoscaler/enabled"           = "true"
    "Name"                                        = "AmazonEKS_EBS_CSI_DriverRole"
  }
}

# IAM Policy for EBS CSI Driver
resource "aws_iam_policy" "ebs_csi_driver_policy" {
  name        = "AmazonEKS_EBS_CSI_Driver_Policy"
  description = "Custom policy for EBS CSI driver using IRSA"
  policy      = data.aws_iam_policy_document.ebs_csi_driver_doc.json
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "ebs_csi_attach" {
  role       = aws_iam_role.ebs_csi_driver_role.name
  policy_arn = aws_iam_policy.ebs_csi_driver_policy.arn
}