provider "aws" {
  region = var.aws_region
}

# Create an IP Set for allowed IP prefixes
resource "aws_wafv2_ip_set" "allowed_ips" {
  name        = var.ip_set_name
  scope       = var.scope # REGIONAL for ALB or CLOUDFRONT for CloudFront
  ip_address_version = "IPV4"
  addresses   = var.allowed_ip_prefix_list

  description = "IP Set for allowed IP prefixes"
}

# Web ACL
resource "aws_wafv2_web_acl" "waf_acl" {
  name        = var.web_acl_name
  scope       = var.scope # REGIONAL or CLOUDFRONT
  description = "WAF v2 ACL with security rules"
  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "webACL"
    sampled_requests_enabled   = true
  }

  # Block requests from non-allowed IP addresses
  rule {
    name     = "IPRestrictionRule"
    priority = 0
    action {
      block {}
    }

    statement {
      not_statement {
        statement {
          ip_set_reference_statement {
            arn = aws_wafv2_ip_set.allowed_ips.arn
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "IPRestrictionRule"
      sampled_requests_enabled   = true
    }
  }

  # AWS managed rule group for DDoS protection
  rule {
    name     = "AWSManagedDDoSProtection"
    priority = 1
    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        vendor_name = "AWS"
        name        = "AWSManagedRulesDDoSProtectionRuleSet"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "DDoSProtection"
      sampled_requests_enabled   = true
    }
  }

  # AWS managed rule group for SQL Injection protection
  rule {
    name     = "AWSManagedSQLi"
    priority = 2
    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        vendor_name = "AWS"
        name        = "AWSManagedRulesSQLiRuleSet"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "SQLInjectionProtection"
      sampled_requests_enabled   = true
    }
  }

  # AWS managed rule group for Cross-Site Scripting (XSS) protection
  rule {
    name     = "AWSManagedXSSProtection"
    priority = 3
    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        vendor_name = "AWS"
        name        = "AWSManagedRulesXSSRuleSet"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "XSSProtection"
      sampled_requests_enabled   = true
    }
  }

  # AWS managed rule group for Common Vulnerabilities and Exposures (CVE)
  rule {
    name     = "AWSManagedCommonVulnerabilitiesProtection"
    priority = 4
    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        vendor_name = "AWS"
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "CVEProtection"
      sampled_requests_enabled   = true
    }
  }

  # Associate the Web ACL with the load balancer (or API Gateway)
  resource "aws_wafv2_web_acl_association" "waf_acl_association" {
    resource_arn = var.resource_arn # ARN of ALB, API Gateway, etc.
    web_acl_arn  = aws_wafv2_web_acl.waf_acl.arn
  }
}