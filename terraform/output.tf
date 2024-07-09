output "ecs_task_definition_arn" {
  value = aws_ecs_task_definition.strapi_task_definition.arn
}

output "ecs_cluster_id" {
  value = aws_ecs_cluster.strapi_cluster.id
}

output "ecs_service_name" {
  value = aws_ecs_service.strapi_service1.name
}

output "ecs_service_task_definition" {
  value = aws_ecs_service.strapi_service1.task_definition
}

output "route53_dns_name" {
  value = aws_route53_record.strapi_subdomain.fqdn
}
