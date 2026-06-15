output "alb_dns_name" {
  value       = aws_lb.web.dns_name
  description = "The public URL of your self-healing web tier load balancer"
}
