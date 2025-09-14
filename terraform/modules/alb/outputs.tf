# ALB Outputs
output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.main.arn
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "Zone ID of the Application Load Balancer"
  value       = aws_lb.main.zone_id
}

output "alb_security_group_id" {
  description = "Security Group ID of the ALB"
  value       = aws_security_group.alb.id
}

# Listener Outputs
output "http_listener_arn" {
  description = "ARN of the HTTP listener"
  value       = aws_lb_listener.http.arn
}

output "https_listener_arn" {
  description = "ARN of the HTTPS listener"
  value       = var.certificate_arn != null ? aws_lb_listener.https[0].arn : null
}

# Target Group Outputs
output "default_target_group_arn" {
  description = "ARN of the default target group"
  value       = aws_lb_target_group.default.arn
}

output "default_target_group_name" {
  description = "Name of the default target group"
  value       = aws_lb_target_group.default.name
}

# Target Group ARNs (for backward compatibility)
output "target_group_arns" {
  description = "List of target group ARNs"
  value       = [aws_lb_target_group.default.arn]
}

# Outputs using expected names for backward compatibility
output "arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.main.arn
}

output "dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "zone_id" {
  description = "Zone ID of the Application Load Balancer"
  value       = aws_lb.main.zone_id
}

output "security_group_id" {
  description = "Security Group ID of the ALB"
  value       = aws_security_group.alb.id
}

# Complete ALB Information
output "alb_info" {
  description = "Complete ALB information"
  value = {
    arn                     = aws_lb.main.arn
    dns_name               = aws_lb.main.dns_name
    zone_id                = aws_lb.main.zone_id
    security_group_id      = aws_security_group.alb.id
    default_target_group_arn = aws_lb_target_group.default.arn
    target_group_arns      = [aws_lb_target_group.default.arn]
    http_listener_arn      = aws_lb_listener.http.arn
    https_listener_arn     = var.certificate_arn != null ? aws_lb_listener.https[0].arn : null
    internal               = var.internal
  }
}