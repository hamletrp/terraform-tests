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

data "aws_iam_policy_document" "pod_identity_association" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }
    actions = [
      "sts:AssumeRole",
      "sts:TagSession"
    ]
  }
}

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
        "system:serviceaccount:platform-system:awsalb-load-balancer-controller-sa",
        "system:serviceaccount:platform-system:external-secrets-awssm-sa",
        "system:serviceaccount:platform-system:karpenter",
        "system:serviceaccount:networking:nginx-ingress-sa",
        "system:serviceaccount:istio-system:istiod-appmesh-sa",
        "system:serviceaccount:istio-system:istio-ingressgateway-sa",
        "system:serviceaccount:platform-system:cert-manager-sa"
      ]
    }
    condition {
      test     = "StringEquals"
      variable = "${replace(var.oidc_provider_url, "https://", "")}:aud"
      values = ["sts.amazonaws.com"]
    }
  }
}

# Configures a clean, cloud-native trust handshake targeting the EKS principal
data "aws_iam_policy_document" "eks_pod_identity_trust_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole", "sts:TagSession"]

    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"] # Pure EKS service trust mechanism
    }
    condition {
      test     = "StringEquals"
      variable = "${replace(var.oidc_provider_url, "https://", "")}:sub"
      values = [
        "system:serviceaccount:platform-system:external-dns-access",
        "system:serviceaccount:httpbingo:ap-abc-sa"
      ]
    }
  }
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
        "system:serviceaccount:httpbingo:ap-abc-sa"
      ]
    }
    condition {
      test     = "StringEquals"
      variable = "${replace(var.oidc_provider_url, "https://", "")}:aud"
      values = ["sts.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "github_actions_role_policy_oidc_provider" {
  statement {
    effect = "Allow"
    principals {
      type        = "Federated"
      identifiers = ["arn:aws:iam::${var.AWS_ACC_ID}:oidc-provider/token.actions.githubusercontent.com"]
    }
    actions = ["sts:AssumeRoleWithWebIdentity"]
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values = ["repo:eksk8s/tests:*"]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
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