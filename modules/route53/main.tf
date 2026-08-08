# Route53 Hosted Zone
resource "aws_route53_zone" "main" {
  name = var.domain_name

  tags = {
    Name = "${var.project_name}-${var.environment}-zone"
  }
}

# Route53 Health Check
resource "aws_route53_health_check" "main" {
  type              = "HTTP"
  resource_path     = "/"
  measure_latency   = true
  enable_sni        = true
  failure_threshold = 3

  tags = {
    Name = "${var.project_name}-${var.environment}-health-check"
  }
}
