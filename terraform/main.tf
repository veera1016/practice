provider "aws" {
  region = "ca-central-1"
}

# VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
}

# Route Table
resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
}

# Subnets
resource "aws_subnet" "main" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.${count.index}.0/24"
  availability_zone = element(data.aws_availability_zones.available.names, count.index)
}

# Route Table Associations
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.main[0].id
  route_table_id = aws_route_table.main.id
}

resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.main[1].id
  route_table_id = aws_route_table.main.id
}

# Security Group
resource "aws_security_group" "main" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 1337
    to_port     = 1337
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# IAM Role for ECS Task Execution
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecs_task_execution_role_unique"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "ashok-ecs-cluster"
}

# ECS Task Definitions
resource "aws_ecs_task_definition" "reactjs" {
  family                   = "reactjs-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  memory                   = "512"
  cpu                      = "256"

  container_definitions = jsonencode([{
    name  = "reactjs-container"
    image = "veera1016/reactjsdocker:latest" # Docker Hub image for ReactJS
    portMappings = [{
      containerPort = 80
      hostPort      = 80
    }]
  }])
}

resource "aws_ecs_task_definition" "strapi" {
  family                   = "strapi-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  memory                   = "512"
  cpu                      = "256"

  container_definitions = jsonencode([{
    name  = "strapi-container"
    image = "veera1016/strapidocker:latest" # Docker Hub image for Strapi
    portMappings = [{
      containerPort = 1337
      hostPort      = 1337
    }]
    environment = [
      {
        name  = "DATABASE_CLIENT"
        value = "sqlite"
      },
      {
        name  = "DATABASE_FILENAME"
        value = "./.tmp/data.db"
      },
      {
        name  = "JWT_SECRET"
        value = "your-jwt-secret"
      },
      {
        name  = "ADMIN_JWT_SECRET"
        value = "your-admin-jwt-secret"
      },
      {
        name  = "NODE_ENV"
        value = "production"
      }
    ]
  }])
}

# ECS Services
resource "aws_ecs_service" "reactjs" {
  name            = "reactjs-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.reactjs.arn
  desired_count   = 1

  network_configuration {
    subnets         = aws_subnet.main[*].id
    security_groups = [aws_security_group.main.id]
    assign_public_ip = true
  }

  capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
    weight = 1
  }

  service_registries {
    registry_arn = aws_service_discovery_service.reactjs.arn
  }
}

resource "aws_ecs_service" "strapi" {
  name            = "strapi-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.strapi.arn
  desired_count   = 1

  network_configuration {
    subnets         = aws_subnet.main[*].id
    security_groups = [aws_security_group.main.id]
    assign_public_ip = true
  }

  capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
    weight = 1
  }

  service_registries {
    registry_arn = aws_service_discovery_service.strapi.arn
  }
}

# Service Discovery
resource "aws_service_discovery_private_dns_namespace" "main" {
  name        = "example"
  description = "Private DNS namespace for ECS services"
  vpc         = aws_vpc.main.id
}

resource "aws_service_discovery_service" "reactjs" {
  name = "reactjs-service"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.main.id

    dns_records {
      ttl  = 10
      type = "A"
    }
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}

resource "aws_service_discovery_service" "strapi" {
  name = "strapi-service"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.main.id

    dns_records {
      ttl  = 10
      type = "A"
    }
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}

data "aws_availability_zones" "available" {}

# Route53 Records
resource "aws_route53_zone" "main" {
  name = "contentecho.in"
}

resource "aws_route53_record" "reactjs_subdomain" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "ashok.contentecho.in"
  type    = "CNAME"
  ttl     = 300
  records = [aws_service_discovery_service.reactjs.name + "." + aws_service_discovery_private_dns_namespace.main.name]
}

resource "aws_route53_record" "strapi_subdomain" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "ashok-api.contentecho.in"
  type    = "CNAME"
  ttl     = 300
  records = [aws_service_discovery_service.strapi.name + "." + aws_service_discovery_private_dns_namespace.main.name]
}

output "ecs_task_definition_arn" {
  value = aws_ecs_task_definition.strapi.arn
}

output "ecs_cluster_id" {
  value = aws_ecs_cluster.main.id
}

output "ecs_service_name" {
  value = aws_ecs_service.strapi.name
}

output "ecs_service_task_definition" {
  value = aws_ecs_service.strapi.task_definition
}

output "route53_dns_name" {
  value = aws_route53_record.strapi_subdomain.fqdn
}
