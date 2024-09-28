variable "namespace" {
  description = "Kubernetes namespace"
  type        = string
}

variable "service_accounts" {
  description = "A map of service accounts to their respective IAM policy file paths"
  type        = map(string)
}

# Loop through each service account and create an IAM role
resource "aws_iam_role" "this" {
  for_each = var.service_accounts

  name = "${var.namespace}-${each.key}-role"

  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRoleWithWebIdentity",
        "Effect": "Allow",
        "Principal": {
          "Federated": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/oidc.eks.${var.region}.amazonaws.com/id/${data.aws_eks_cluster.this.identity[0].oidc.issuer.split("https://")[1]}"
        },
        "Condition": {
          "StringEquals": {
            "oidc.eks.${var.region}.amazonaws.com/id/${data.aws_eks_cluster.this.identity[0].oidc.issuer.split("https://")[1]}:sub": "system:serviceaccount:${var.namespace}:${each.key}"
          }
        }
      }
    ]
  })
}

# Read IAM policy from file for each service account
data "aws_iam_policy_document" "this" {
  for_each = var.service_accounts
  source   = file(each.value)
}

resource "aws_iam_role_policy" "this" {
  for_each = var.service_accounts

  name   = "${var.namespace}-${each.key}-policy"
  role   = aws_iam_role.this[each.key].name
  policy = data.aws_iam_policy_document.this[each.key].json
}