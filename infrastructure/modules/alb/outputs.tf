output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.main.arn
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "Hosted zone ID of the Application Load Balancer"
  value       = aws_lb.main.zone_id
}

output "listener_arn" {
  description = "ARN of the ALB listener"
  value       = aws_lb_listener.main.arn
}

output "target_groups" {
  description = "Map of service names to target group ARNs"
  value = {
    orders_service    = aws_lb_target_group.orders_service.arn
    inventory_service = aws_lb_target_group.inventory_service.arn
    prometheus        = aws_lb_target_group.prometheus.arn
    grafana          = aws_lb_target_group.grafana.arn
  }
}

output "target_group_arns" {
  description = "List of all target group ARNs"
  value = [
    aws_lb_target_group.orders_service.arn,
    aws_lb_target_group.inventory_service.arn,
    aws_lb_target_group.prometheus.arn,
    aws_lb_target_group.grafana.arn
  ]
}