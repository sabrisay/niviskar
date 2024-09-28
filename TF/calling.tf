variable "namespace_service_accounts" {
  description = "A map of namespaces to service accounts and their respective IAM policy filenames (without path)"
  type = map(map(string))
  default = {
    "namespace1" = {
      "serviceaccount1" = "serviceaccount1_policy.json",
      "serviceaccount2" = "serviceaccount2_policy.json"
    },
    "namespace2" = {
      "serviceaccount1" = "serviceaccount1_policy.json",
      "serviceaccount2" = "serviceaccount2_policy.json"
    }
    # Add more namespaces and service accounts here
  }
}

# Define the base directory where policies are stored
locals {
  base_policy_path = "${path.module}/iam-policies/dev"
}

# Loop through the namespace and service accounts
module "iam_roles" {
  source = "./modules/iam_role_creation"

  for_each = { 
    for namespace, service_accounts in var.namespace_service_accounts : 
    "${namespace}" => service_accounts 
  }

  namespace = each.key

  # Create IAM roles for each service account inside the namespace
  service_accounts = {
    for service_account, policy_file in each.value :
    service_account => "${local.base_policy_path}/${policy_file}"
  }
}