resource "aws_wafv2_web_acl" "example" {
  name        = "example-web-acl"
  scope       = "REGIONAL" # Use "CLOUDFRONT" for CloudFront
  description = "Web ACL with Bot Control"
  default_action {
    allow {}
  }
  rule {
    name     = "BotControlRule"
    priority = 1
    action {
      block {}
    }
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesBotControlRuleSet"
        vendor_name = "AWS"
      }
    }
    override_action {
      none {}
    }
  }
  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "web-acl-example"
    sampled_requests_enabled   = true
  }
}