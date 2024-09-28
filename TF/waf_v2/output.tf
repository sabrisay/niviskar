output "web_acl_arn" {
  description = "The ARN of the WAF Web ACL"
  value       = aws_wafv2_web_acl.waf_acl.arn
}

output "allowed_ips_arn" {
  description = "The ARN of the IP Set for allowed IP prefixes"
  value       = aws_wafv2_ip_set.allowed_ips.arn
}