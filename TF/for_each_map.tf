variable "namespace_service_accounts" {
  description = "A map of namespace to service accounts and their respective IAM policy file paths"
  type = map(map(string))
  default = {
    "namespace1" = {
      "serviceaccount1" = "${path.module}/iam-policies/dev/serviceaccount1_policy.json",
      "serviceaccount2" = "${path.module}/iam-policies/dev/serviceaccount2_policy.json"
    }
    "namespace2" = {
      "serviceaccount1" = "${path.module}/iam-policies/dev/serviceaccount1_policy.json",
      "serviceaccount2" = "${path.module}/iam-policies/dev/serviceaccount2_policy.json"
    }
    # Add more namespaces and service accounts here
  }
}

# Loop through the namespace and service accounts
locals {
  namespaces = keys(var.namespace_service_accounts)
}

# Create IAM roles for each namespace and service account
module "iam_roles" {
  source               = "./modules/iam_role_creation"
  for_each             = { for ns, sa_map in var.namespace_service_accounts : ns => sa_map }
  namespace            = each.key
  service_account_name = keys(each.value)[0]
  iam_policy_file      = values(each.value)[0]
}