provider "aws" {
  profile = "default"
  region  = "us-east-1"
}

resource "aws_iam_role" "cluster_autoscaler_role" {
  name               = "${var.eks_role_name}-${var.cluster_name}"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy_oidc_provider.json
}

resource "aws_iam_policy" "cluster_autoscaler_policy" {
  name        = "eks-cluster-autoscaler-policy-${var.cluster_name}"
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
    "alpha.eksctl.io/nodegroup-name"                = "${var.nodegroup_name}"
    "k8s.io/cluster-autoscaler/${var.cluster_name}" = "owned"
    "environment"                                   = "${var.environment}"
    "alpha.eksctl.io/cluster-name"                  = "${var.cluster_name}"
    "eksctl.cluster.k8s.io/v1alpha1/cluster-name"   = "${var.cluster_name}"
    "alpha.eksctl.io/nodegroup-type"                = "managed"
    "team"                                          = "platform"
    "k8s.io/cluster-autoscaler/enabled"             = "true"
    "alpha.eksctl.io/eksctl-version"                = "0.207.0"
    "Name"                                          = "eksctl-${var.cluster_name}-nodegroup-linux-nodes3/NodeInstanceRole"
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
  name        = "eks-node-group-inline-policy-${var.cluster_name}"
  description = "Policy for ec2 instance nodes role"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ec2:CreateVolume",
          "ec2:AttachVolume",
          "ec2:DetachVolume",
          "ec2:DeleteVolume",
          "ec2:CreateTags",
          "elasticloadbalancing:DescribeLoadBalancers"
        ],
        Resource = ["*"]
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
  name = "AmazonEKS_EBS_CSI_DriverRole-${var.cluster_name}"

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
  name        = "AmazonEKS_EBS_CSI_Driver_Policy-${var.cluster_name}"
  description = "Custom policy for EBS CSI driver using IRSA"
  policy      = data.aws_iam_policy_document.ebs_csi_driver_doc.json
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "ebs_csi_attach" {
  role       = aws_iam_role.ebs_csi_driver_role.name
  policy_arn = aws_iam_policy.ebs_csi_driver_policy.arn
}

resource "aws_iam_role" "eks_alb_controller_irsa_role" {
  name               = "eks-alb-controller-role-${var.cluster_name}"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy_oidc_provider.json
}

resource "aws_iam_policy" "alb_controller_policy" {
  name = "AWSLoadBalancerControllerIAMPolicy-${var.cluster_name}"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "iam:CreateServiceLinkedRole"
        ],
        "Resource" : "*",
        "Condition" : {
          "StringEquals" : {
            "iam:AWSServiceName" : "elasticloadbalancing.amazonaws.com"
          }
        }
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "ec2:DescribeAccountAttributes",
          "ec2:DescribeAddresses",
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeInternetGateways",
          "ec2:DescribeVpcs",
          "ec2:DescribeVpcPeeringConnections",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeInstances",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DescribeTags",
          "ec2:GetCoipPoolUsage",
          "ec2:DescribeCoipPools",
          "ec2:GetSecurityGroupsForVpc",
          "ec2:DescribeIpamPools",
          "ec2:DescribeRouteTables",
          "elasticloadbalancing:DescribeLoadBalancers",
          "elasticloadbalancing:DescribeLoadBalancerAttributes",
          "elasticloadbalancing:DescribeListeners",
          "elasticloadbalancing:DescribeListenerCertificates",
          "elasticloadbalancing:DescribeSSLPolicies",
          "elasticloadbalancing:DescribeRules",
          "elasticloadbalancing:DescribeTargetGroups",
          "elasticloadbalancing:DescribeTargetGroupAttributes",
          "elasticloadbalancing:DescribeTargetHealth",
          "elasticloadbalancing:DescribeTags",
          "elasticloadbalancing:DescribeTrustStores",
          "elasticloadbalancing:DescribeListenerAttributes",
          "elasticloadbalancing:DescribeCapacityReservation"
        ],
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "cognito-idp:DescribeUserPoolClient",
          "acm:ListCertificates",
          "acm:DescribeCertificate",
          "iam:ListServerCertificates",
          "iam:GetServerCertificate",
          "waf-regional:GetWebACL",
          "waf-regional:GetWebACLForResource",
          "waf-regional:AssociateWebACL",
          "waf-regional:DisassociateWebACL",
          "wafv2:GetWebACL",
          "wafv2:GetWebACLForResource",
          "wafv2:AssociateWebACL",
          "wafv2:DisassociateWebACL",
          "shield:GetSubscriptionState",
          "shield:DescribeProtection",
          "shield:CreateProtection",
          "shield:DeleteProtection"
        ],
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupIngress"
        ],
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "ec2:CreateSecurityGroup"
        ],
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "ec2:CreateTags"
        ],
        "Resource" : "arn:aws:ec2:*:*:security-group/*",
        "Condition" : {
          "StringEquals" : {
            "ec2:CreateAction" : "CreateSecurityGroup"
          },
          "Null" : {
            "aws:RequestTag/elbv2.k8s.aws/cluster" : "false"
          }
        }
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "ec2:CreateTags",
          "ec2:DeleteTags"
        ],
        "Resource" : "arn:aws:ec2:*:*:security-group/*",
        "Condition" : {
          "Null" : {
            "aws:RequestTag/elbv2.k8s.aws/cluster" : "true",
            "aws:ResourceTag/elbv2.k8s.aws/cluster" : "false"
          }
        }
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupIngress",
          "ec2:DeleteSecurityGroup"
        ],
        "Resource" : "*",
        "Condition" : {
          "Null" : {
            "aws:ResourceTag/elbv2.k8s.aws/cluster" : "false"
          }
        }
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "elasticloadbalancing:CreateLoadBalancer",
          "elasticloadbalancing:CreateTargetGroup"
        ],
        "Resource" : "*",
        "Condition" : {
          "Null" : {
            "aws:RequestTag/elbv2.k8s.aws/cluster" : "false"
          }
        }
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "elasticloadbalancing:CreateListener",
          "elasticloadbalancing:DeleteListener",
          "elasticloadbalancing:CreateRule",
          "elasticloadbalancing:DeleteRule"
        ],
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "elasticloadbalancing:AddTags",
          "elasticloadbalancing:RemoveTags"
        ],
        "Resource" : [
          "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*",
          "arn:aws:elasticloadbalancing:*:*:loadbalancer/net/*/*",
          "arn:aws:elasticloadbalancing:*:*:loadbalancer/app/*/*"
        ],
        "Condition" : {
          "Null" : {
            "aws:RequestTag/elbv2.k8s.aws/cluster" : "true",
            "aws:ResourceTag/elbv2.k8s.aws/cluster" : "false"
          }
        }
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "elasticloadbalancing:AddTags",
          "elasticloadbalancing:RemoveTags"
        ],
        "Resource" : [
          "arn:aws:elasticloadbalancing:*:*:listener/net/*/*/*",
          "arn:aws:elasticloadbalancing:*:*:listener/app/*/*/*",
          "arn:aws:elasticloadbalancing:*:*:listener-rule/net/*/*/*",
          "arn:aws:elasticloadbalancing:*:*:listener-rule/app/*/*/*"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "elasticloadbalancing:ModifyLoadBalancerAttributes",
          "elasticloadbalancing:SetIpAddressType",
          "elasticloadbalancing:SetSecurityGroups",
          "elasticloadbalancing:SetSubnets",
          "elasticloadbalancing:DeleteLoadBalancer",
          "elasticloadbalancing:ModifyTargetGroup",
          "elasticloadbalancing:ModifyTargetGroupAttributes",
          "elasticloadbalancing:DeleteTargetGroup",
          "elasticloadbalancing:ModifyListenerAttributes",
          "elasticloadbalancing:ModifyCapacityReservation",
          "elasticloadbalancing:ModifyIpPools"
        ],
        "Resource" : "*",
        "Condition" : {
          "Null" : {
            "aws:ResourceTag/elbv2.k8s.aws/cluster" : "false"
          }
        }
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "elasticloadbalancing:AddTags"
        ],
        "Resource" : [
          "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*",
          "arn:aws:elasticloadbalancing:*:*:loadbalancer/net/*/*",
          "arn:aws:elasticloadbalancing:*:*:loadbalancer/app/*/*"
        ],
        "Condition" : {
          "StringEquals" : {
            "elasticloadbalancing:CreateAction" : [
              "CreateTargetGroup",
              "CreateLoadBalancer"
            ]
          },
          "Null" : {
            "aws:RequestTag/elbv2.k8s.aws/cluster" : "false"
          }
        }
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "elasticloadbalancing:RegisterTargets",
          "elasticloadbalancing:DeregisterTargets"
        ],
        "Resource" : "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "elasticloadbalancing:SetWebAcl",
          "elasticloadbalancing:ModifyListener",
          "elasticloadbalancing:AddListenerCertificates",
          "elasticloadbalancing:RemoveListenerCertificates",
          "elasticloadbalancing:ModifyRule",
          "elasticloadbalancing:SetRulePriorities"
        ],
        "Resource" : "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "alb_controller_attach" {
  role       = aws_iam_role.eks_alb_controller_irsa_role.name
  policy_arn = aws_iam_policy.alb_controller_policy.arn
}

resource "aws_iam_role" "eks_cni_role" {
  name = "AmazonEKS_CNI_Role-${var.cluster_name}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "eks.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
  tags = {
    Name        = "AmazonEKS_CNI_Role-${var.cluster_name}"
    Environment = "${var.environment}"
  }
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy_attach" {
  role       = aws_iam_role.eks_cni_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}


resource "aws_iam_role" "aws_lb_controller_role" {
  name               = "AmazonEKSLoadBalancerControllerRole-${var.cluster_name}"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy_oidc_provider.json

  tags = {
    "eksctl.cluster.k8s.io/v1alpha1/cluster-name" = var.cluster_name
    "eks.amazonaws.com/component"                 = "aws-load-balancer-controller"
    "eks.amazonaws.com/role-alb-ingress"          = "true"
  }
}

resource "aws_iam_role_policy_attachment" "attach_lb_controller_policy" {
  role       = aws_iam_role.aws_lb_controller_role.name
  policy_arn = "arn:aws:iam::${var.AWS_ACC_ID}:policy/AWSLoadBalancerControllerIAMPolicy-${var.cluster_name}"
}

resource "aws_iam_role" "eso_irsa_role" {
  name               = "eso-awssm-irsa-role-${var.cluster_name}"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy_oidc_provider.json
}

resource "aws_iam_role_policy_attachment" "eso_irsa_policy_attach" {
  role       = aws_iam_role.eso_irsa_role.name
  policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite" # or create custom policy with minimal access
}

resource "aws_iam_role_policy_attachment" "eso_irsa_policy_attach_2" {
  role       = aws_iam_role.eso_irsa_role.name
  policy_arn = "arn:aws:iam::722249351142:policy/SSMParamStore-FullRead" # or create custom policy with minimal access
}

resource "aws_iam_role" "karpenter_nodes_role" {
  name               = "eksctl-${var.cluster_name}-karpenter-nodes-role"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.eks_assume_role_policy.json

  tags = {
    "alpha.eksctl.io/nodegroup-name"                = "${var.nodegroup_name}"
    "environment"                                   = "${var.environment}"
    "alpha.eksctl.io/cluster-name"                  = "${var.cluster_name}"
    "eksctl.cluster.k8s.io/v1alpha1/cluster-name"   = "${var.cluster_name}"
    "alpha.eksctl.io/nodegroup-type"                = "managed"
    "team"                                          = "platform"
    "alpha.eksctl.io/eksctl-version"                = "0.207.0"
  }
}

resource "aws_iam_role_policy_attachment" "karpenter_node_policy" {
  role       = aws_iam_role.karpenter_nodes_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_instance_profile" "karpenter_instance_profile" {
  name = "KarpenterInstanceProfile-${var.cluster_name}"
  role = aws_iam_role.karpenter_nodes_role.name
}

resource "aws_iam_role" "karpenter_controller_role" {
  name               = "KarpenterControllerRole-${var.cluster_name}"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy_oidc_provider.json
}

resource "aws_iam_role_policy" "karpenter_controller_inline" {
  name = "KarpenterControllerPolicy-${var.cluster_name}"
  role = aws_iam_role.karpenter_controller_role.name
  policy = file("karpenter-controller-policy.json")
}

resource "aws_sqs_queue" "karpenter_interruption_queue" {
  name                      = "karpenter-interruption-queue-${var.cluster_name}"
  message_retention_seconds = 300  # 5 minutes
  visibility_timeout_seconds = 30

  tags = {
    Environment = "${var.environment}"
    Application = "karpenter"
  }
}

resource "aws_sns_topic" "karpenter_health_alerts" {
  name = "KarpenterHealthAlertsTopic"
}

resource "aws_sns_topic_policy" "allow_cloudwatch_publish" {
  arn    = aws_sns_topic.karpenter_health_alerts.arn
  policy = data.aws_iam_policy_document.sns_topic_policy.json
}
resource "aws_sns_topic_subscription" "email_subscription" {
  topic_arn = aws_sns_topic.karpenter_health_alerts.arn
  protocol  = "email"
  endpoint  = "hamletrp@gmail.com"
}

resource "aws_sns_topic_subscription" "sms_subscription" {
  topic_arn = aws_sns_topic.karpenter_health_alerts.arn
  protocol  = "sms"
  endpoint  = "16315605543"
}

resource "aws_cloudwatch_metric_alarm" "interruption_queue_alarm" {
  alarm_name          = "KarpenterInterruptionQueueDepth"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 300
  statistic           = "Average"
  threshold           = 1

  dimensions = {
    QueueName = aws_sqs_queue.karpenter_interruption_queue.name
  }

  alarm_description = "Triggered when more than 1 interruption messages are in the queue"
  treat_missing_data = "notBreaching"

   alarm_actions = [aws_sns_topic.karpenter_health_alerts.arn]
  
}

resource "aws_sqs_queue_policy" "karpenter_interruption_queue_policy" {
  queue_url = aws_sqs_queue.karpenter_interruption_queue.id

  policy = jsonencode({
    Id = "EC2InterruptionPolicy"
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = [
            "events.amazonaws.com",
            "sqs.amazonaws.com"
          ]
        }
        Action = "sqs:SendMessage"
        Resource = aws_sqs_queue.karpenter_interruption_queue.arn
      },
      {
        Sid = "DenyHTTP"
        Effect = "Deny"
        Principal = "*"
        Action = "sqs:*"
        Resource = aws_sqs_queue.karpenter_interruption_queue.arn
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}

resource "aws_cloudwatch_event_rule" "scheduled_change_rule" {
  name        = "scheduled-change-rule"
  description = "Triggers on AWS Health Events"
  event_pattern = jsonencode({
    source      = ["aws.health"]
    "detail-type" = ["AWS Health Event"]
  })
}

resource "aws_cloudwatch_event_target" "scheduled_change_target" {
  rule      = aws_cloudwatch_event_rule.scheduled_change_rule.name
  target_id = "KarpenterInterruptionQueueTarget"
  arn       = aws_sqs_queue.karpenter_interruption_queue.arn
}

resource "aws_cloudwatch_event_rule" "spot_interruption_rule" {
  name        = "SpotInterruptionRule"
  description = "Triggers on EC2 Spot Instance Interruption Warnings"
  event_pattern = jsonencode({
    "source": ["aws.ec2"],
    "detail-type": ["EC2 Spot Instance Interruption Warning"]
  })
}

resource "aws_cloudwatch_event_target" "karpenter_interruption_target" {
  rule      = aws_cloudwatch_event_rule.spot_interruption_rule.name
  target_id = "KarpenterInterruptionQueueTarget"
  arn       = aws_sqs_queue.karpenter_interruption_queue.arn
}


resource "aws_cloudwatch_event_rule" "rebalance_rule" {
  name        = "RebalanceRule"
  description = "Triggers on EC2 Instance Rebalance Recommendation"
  event_pattern = jsonencode({
    "source"      : ["aws.ec2"],
    "detail-type": ["EC2 Instance Rebalance Recommendation"]
  })
}

resource "aws_cloudwatch_event_target" "rebalance_target" {
  rule      = aws_cloudwatch_event_rule.rebalance_rule.name
  target_id = "KarpenterInterruptionQueueTarget"
  arn       = aws_sqs_queue.karpenter_interruption_queue.arn
}

resource "aws_cloudwatch_event_rule" "instance_state_change_rule" {
  name        = "instance-state-change-rule"
  description = "Triggers on EC2 instance state change events"
  event_pattern = jsonencode({
    "source": ["aws.ec2"],
    "detail-type": ["EC2 Instance State-change Notification"]
  })
}

resource "aws_cloudwatch_event_target" "karpenter_interruption_queue_target" {
  rule      = aws_cloudwatch_event_rule.instance_state_change_rule.name
  target_id = "KarpenterInterruptionQueueTarget"
  arn       = aws_sqs_queue.karpenter_interruption_queue.arn
}



resource "aws_iam_policy" "karpenter_sqs_access_policy" {
  name        = "karpenter_sqs_access_policy-${var.cluster_name}"
  description = "Policy karpenter interrumption queue"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:GetQueueUrl",
          "sqs:ReceiveMessage"
        ],
        Resource = aws_sqs_queue.karpenter_interruption_queue.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "karpenter_sqs_policy_attachment" {
  role       = aws_iam_role.karpenter_controller_role.name
  policy_arn = aws_iam_policy.karpenter_sqs_access_policy.arn
}

# -------------------------
# 1. VPC
# -------------------------
# resource "aws_vpc" "eks_vpc1" {
#   cidr_block           = "10.0.0.0/16"
#   enable_dns_support   = true
#   enable_dns_hostnames = true

#   tags = {
#     Name = "eks-vpc-${var.cluster_name}"
#   }
# }

# # resource "aws_vpc_dhcp_options" "custom_dhcp" {
# #   domain_name          = "ec2.internal"
# #   domain_name_servers  = ["AmazonProvidedDNS"]
# #   ntp_servers          = ["169.254.169.123"]
# #   netbios_name_servers = ["10.0.0.1"]
# #   netbios_node_type    = 2

# #   tags = {
# #     Name = "custom-dhcp-options-${var.cluster_name}"
# #   }
# # }

# # resource "aws_vpc_dhcp_options_association" "dhcp_association" {
# #   vpc_id          = aws_vpc.eks_vpc1.id
# #   dhcp_options_id = aws_vpc_dhcp_options.custom_dhcp.id
# # }


# # -------------------------
# # 2. Internet Gateway
# # -------------------------
# resource "aws_internet_gateway" "eks_igw1" {
#   vpc_id = aws_vpc.eks_vpc1.id

#   tags = {
#     Name = "eks-igw-${var.cluster_name}"
#   }
# }

# # -------------------------
# # 3. Public & Private Subnets (x3 AZs)
# # -------------------------
# locals {
#   azs             = slice(data.aws_availability_zones.available.names, 0, 3)
#   public_subnets  = [for i in range(3) : cidrsubnet("10.0.0.0/16", 8, i)]
#   private_subnets = [for i in range(3) : cidrsubnet("10.0.0.0/16", 8, i + 10)]
# }

# resource "aws_subnet" "eks_subnet_public1" {
#   count                   = 3
#   vpc_id                 = aws_vpc.eks_vpc1.id
#   cidr_block             = local.public_subnets[count.index]
#   availability_zone      = local.azs[count.index]
#   map_public_ip_on_launch = true

#   tags = {
#     Name                               = "eks-subnet-public1-${var.cluster_name}-${local.azs[count.index]}"
#     "kubernetes.io/role/elb"           = "1"
#     "kubernetes.io/cluster/eks-cluster" = "owned"
#     "karpenter.sh/discovery"            = var.cluster_name
#     "kubernetes.io/cluster/cluster-lab-1" = "owned"
#     "kubernetes.io/role/elb" = "1"
#     "alb.ingress.kubernetes.io/group.name" = "devops-group"
#   }
# }

# resource "aws_subnet" "eks_subnet_private1" {
#   count              = 3
#   vpc_id             = aws_vpc.eks_vpc1.id
#   cidr_block         = local.private_subnets[count.index]
#   availability_zone  = local.azs[count.index]

#   tags = {
#     Name                                    = "eks-subnet-private1-${var.cluster_name}-${local.azs[count.index]}"
#     "kubernetes.io/role/internal-elb"       = "1"
#     "kubernetes.io/cluster/eks-cluster"     = "owned"
#     "karpenter.sh/discovery"            = var.cluster_name
#     "kubernetes.io/cluster/cluster-lab-1" = "owned"
#     "kubernetes.io/role/internal-elb" = "1"
#   }
# }

# # -------------------------
# # 4. NAT Gateways (1 per AZ)
# # -------------------------
# resource "aws_eip" "eks_nat_1" {
#   count = 3
#   tags = {
#     Name = "eks-eip-${var.cluster_name}"
#   }
# }

# resource "aws_nat_gateway" "eks_natgtw1" {
#   count         = 3
#   allocation_id = aws_eip.eks_nat_1[count.index].id
#   subnet_id     = aws_subnet.eks_subnet_public1[count.index].id

#   tags = {
#     Name = "eks-natgtw1-${var.cluster_name}-${local.azs[count.index]}"
#   }
#   depends_on = [aws_internet_gateway.eks_igw1]
# }

# # -------------------------
# # 5. Route Tables
# # -------------------------
# resource "aws_route_table" "eks_route_table_public1" {
#   vpc_id = aws_vpc.eks_vpc1.id

#   route {
#     cidr_block = "0.0.0.0/0"
#     gateway_id = aws_internet_gateway.eks_igw1.id
#   }

#   tags = {
#     Name = "eks-route-table-public1-${var.cluster_name}"
#   }
# }

# resource "aws_route_table" "eks_route_table_private1" {
#   count  = 3
#   vpc_id = aws_vpc.eks_vpc1.id

#   route {
#     cidr_block     = "0.0.0.0/0"
#     nat_gateway_id = aws_nat_gateway.eks_natgtw1[count.index].id
#   }

#   tags = {
#     Name = "eks-route-table-private1-${var.cluster_name}-${local.azs[count.index]}"
#   }
# }

# # Associate subnets with route tables
# resource "aws_route_table_association" "eks_aws_route_table_associationpublic1" {
#   count          = 3
#   subnet_id      = aws_subnet.eks_subnet_public1[count.index].id
#   route_table_id = aws_route_table.eks_route_table_public1.id
# }

# resource "aws_route_table_association" "aws_route_table_association_private1" {
#   count          = 3
#   subnet_id      = aws_subnet.eks_subnet_private1[count.index].id
#   route_table_id = aws_route_table.eks_route_table_private1[count.index].id
# }

# resource "aws_security_group" "eks_cluster_sg" {
#   name        = "eks-cluster-sg-${var.cluster_name}"
#   description = "EKS Cluster Security Group"
#   vpc_id      = aws_vpc.eks_vpc1.id

#   tags = {
#     Name                                     = "eks-cluster-sg-${var.cluster_name}"
#     Environment                              = var.environment
#     "kubernetes.io/cluster/my-eks-cluster"   = "owned"
#     "karpenter.sh/discovery"                 = var.cluster_name
#   }
# }

# resource "aws_security_group" "eks_node_sg" {
#   name        = "eks-node-sg-${var.cluster_name}"
#   description = "EKS Node Security Group"
#   vpc_id      = aws_vpc.eks_vpc1.id

#   # Allow worker nodes to communicate with each other
#   ingress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     self        = true
#   }

#   # Allow nodes to receive traffic from cluster control plane
#   ingress {
#     description     = "Allow from EKS control plane"
#     from_port       = 443
#     to_port         = 443
#     protocol        = "tcp"
#     security_groups = [aws_security_group.eks_cluster_sg.id]
#   }

#   # Allow all outbound
#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   tags = {
#     Name                                     = "eks-node-sg-${var.cluster_name}"
#     Environment                              = "prod"
#     "kubernetes.io/cluster/my-eks-cluster"   = "owned"
#     "karpenter.sh/discovery"                 = var.cluster_name
#   }
# }

## comment out cuz deploying a new cluster
# resource "aws_s3_bucket" "terraform_state" {
#   bucket = var.terraform_s3_bucket_name
#   force_destroy = true
#   tags = {
#     Name        = "Terraform State Bucket"
#   }
# }


# resource "aws_dynamodb_table" "terraform_locks" {
#   name         = var.terraform_dynamodb_table_name
#   billing_mode = "PAY_PER_REQUEST"
#   hash_key     = "LockID"

#   attribute {
#     name = "LockID"
#     type = "S"
#   }

#   tags = {
#     Name        = "Terraform Lock Table"
#   }
# }
