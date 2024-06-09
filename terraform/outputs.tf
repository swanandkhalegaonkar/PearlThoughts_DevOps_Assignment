output "ecs_cluster_name" {
  value = aws_ecs_cluster.sk_devops_cluster.name
}

output "ecs_service_name" {
  value = aws_ecs_service.sk_devops_service.name
}

output "load_balancer_dns_name" {
  value = aws_lb.sk_devops_lb.dns_name
}
