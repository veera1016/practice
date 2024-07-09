resource "aws_ecs_cluster" "ecs_cluster" {
  name = "ecs-cluster"
}

resource "aws_ecs_task_definition" "react_task" {
  family                   = "react-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512

  container_definitions = jsonencode([
    {
      name  = "react-container"
      image = "veera1016/reactjsdocker:latest"
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
    }
  ])
}

resource "aws_ecs_task_definition" "strapi_task" {
  family                   = "strapi-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512

  container_definitions = jsonencode([
    {
      name  = "strapi-container"
      image = "veera1016/strapidocker:latest"
      essential = true
      portMappings = [
        {
          containerPort = 1337
          hostPort      = 1337
        }
      ]
    }
  ])
}

resource "aws_ecs_service" "react_service" {
  name            = "react-service"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.react_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  network_configuration {
    subnets         = var.subnet_ids
    assign_public_ip = true
    security_groups = [aws_security_group.ecs_sg.id]
  }
}

resource "aws_ecs_service" "strapi_service" {
  name            = "strapi-service"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.strapi_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  network_configuration {
    subnets         = var.subnet_ids
    assign_public_ip = true
    security_groups = [aws_security_group.ecs_sg.id]
  }
}

resource "aws_security_group" "ecs_sg" {
  vpc_id = var.vpc_id

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

resource "aws_route53_record" "react_record" {
  zone_id = "Z06607023RJWXGXD2ZL6M"
  name    = "togaruashok1996.contentecho.in"
  type    = "A"
  alias {
    name                   = aws_ecs_service.react_service.network_configuration[0].assign_public_ip
    zone_id                = "Z06607023RJWXGXD2ZL6M"
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "strapi_record" {
  zone_id = "Z06607023RJWXGXD2ZL6M"
  name    = "togaruashok1996-api.contentecho.in"
  type    = "A"
  alias {
    name                   = aws_ecs_service.strapi_service.network_configuration[0].assign_public_ip
    zone_id                = "Z06607023RJWXGXD2ZL6M"
    evaluate_target_health = false
  }
}
