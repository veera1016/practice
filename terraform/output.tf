output "reactjs_task_definition_arn" {
  value = aws_ecs_task_definition.reactjs.arn
}

output "strapi_task_definition_arn" {
  value = aws_ecs_task_definition.strapi.arn
}

output "ecs_cluster_id" {
  value = aws_ecs_cluster.main.id
}

output "reactjs_service_name" {
  value = aws_ecs_service.reactjs.name
}

output "strapi_service_name" {
  value = aws_ecs_service.strapi.name
}

output "reactjs_route53_dns_name" {
  value = aws_route53_record.reactjs_subdomain.fqdn
}

output "strapi_route53_dns_name" {
  value = aws_route53_record.strapi_subdomain.fqdn
}
