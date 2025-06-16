data "aws_iam_policy_document" "eks_assume_role_policy" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_availability_zones" "available" {}

data "aws_iam_policy_document" "assume_role_policy_oidc_provider" {
  statement {
    effect = "Allow"
    principals {
      type        = "Federated"
      identifiers = ["arn:aws:iam::${var.AWS_ACC_ID}:oidc-provider/${var.oidc_provider}"]
    }
    actions = ["sts:AssumeRoleWithWebIdentity"]
    condition {
      test     = "StringEquals"
      variable = "${replace(var.oidc_provider_url, "https://", "")}:sub"
      values = [
        "system:serviceaccount:performance:cluster-autoscaler-aws-cluster-autoscaler",
        "system:serviceaccount:kube-system:ebs-csi-controller-sa",
        "system:serviceaccount:networking:awsalb-load-balancer-controller-sa",
        "system:serviceaccount:external-secrets:external-secrets-awssm-sa",
        "system:serviceaccount:karpenter:karpenter",
        "system:serviceaccount:networking:nginx-ingress-sa",
        "system:serviceaccount:istio-system:istiod-appmesh-sa",
        "system:serviceaccount:istio-system:istio-ingressgateway-sa",
        "system:serviceaccount:cert-manager:cert-manager-sa"
      ]
    }
    condition {
      test     = "StringEquals"
      variable = "${replace(var.oidc_provider_url, "https://", "")}:aud"
      values = ["sts.amazonaws.com"]
    }
  }
}


data "aws_iam_policy_document" "ebs_csi_driver_doc" {
  statement {
    effect = "Allow"
    actions = [
      "ec2:AttachVolume",
      "ec2:DetachVolume",
      "ec2:ModifyVolume",
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribeInstances",
      "ec2:DescribeVolumes",
      "ec2:DescribeSnapshots",
      "ec2:CreateSnapshot",
      "ec2:DeleteSnapshot",
      "ec2:CreateTags",
      "ec2:DeleteTags",
      "ec2:CreateVolume",
      "ec2:DeleteVolume"
    ]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "sns_topic_policy" {
  statement {
    sid    = "AllowCloudWatch"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudwatch.amazonaws.com"]
    }

    actions   = ["SNS:Publish"]
    resources = [aws_sns_topic.karpenter_health_alerts.arn]
  }
}