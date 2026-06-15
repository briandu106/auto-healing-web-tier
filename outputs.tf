output "alb_dns_name" {
  value       = module.compute.alb_dns_name
  description = "The public URL of the self-healing web tier load balancer"
}
