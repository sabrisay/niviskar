variable "aws_region" {
  type        = string
  description = "AWS Region"
  default     = "us-east-1"
}

variable "scope" {
  type        = string
  description = "Scope of WAF: CLOUDFRONT or REGIONAL"
  default     = "REGIONAL"
}

variable "web_acl_name" {
  type        = string
  description = "Name of the Web ACL"
  default     = "MyWAFACL"
}

variable "ip_set_name" {
  type        = string
  description = "Name of the IP Set for allowed IP prefixes"
  default     = "AllowedIPSet"
}

variable "allowed_ip_prefix_list" {
  type        = list(string)
  description = "List of allowed IP prefixes in CIDR notation"
  default     = ["192.168.1.0/24", "203.0.113.0/24"]
}

variable "resource_arn" {
  type        = string
  description = "ARN of the resource (e.g., ALB or API Gateway) to associate with WAF"
}