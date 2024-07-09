output "react_service_url" {
  value = aws_route53_record.react_record.name
}

output "strapi_service_url" {
  value = aws_route53_record.strapi_record.name
}
