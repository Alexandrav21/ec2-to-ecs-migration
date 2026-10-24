resource "aws_security_group_rule" "ecs_ingress_from_alb" {
  type                     = "ingress"
  description              = "Allow application traffic from the ALB"
  from_port                = var.container_port
  to_port                  = var.container_port
  protocol                 = "tcp"
  security_group_id        = var.task_security_group
  source_security_group_id = var.alb_security_group_id
}

resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-${var.environment}"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-ecs-cluster"
  }
}

resource "aws_ecs_task_definition" "app" {
  family                   = "${var.project_name}-${var.environment}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.cpu
  memory                   = var.memory

  execution_role_arn = var.execution_role_arn
  task_role_arn      = var.task_role_arn

  container_definitions = jsonencode([
    {
      name      = "legacy-api"
      image     = "${var.ecr_repository_url}:${var.image_tag}"
      essential = true

      portMappings = [
        {
          containerPort = var.container_port
          hostPort      = var.container_port
          protocol      = "tcp"
        }
      ]

      healthCheck = {
        command = [
          "CMD-SHELL",
          "python -c \"import urllib.request; urllib.request.urlopen('http://127.0.0.1:${var.container_port}/health', timeout=3)\""
        ]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 10
      }

      logConfiguration = {
        logDriver = "awslogs"

        options = {
          awslogs-group         = var.log_group_name
          awslogs-region        = "eu-west-2"
          awslogs-stream-prefix = "ecs"
        }
      }

      environment = [
        {
          name  = "ENVIRONMENT"
          value = var.environment
        }
      ]
    }
  ])

  tags = {
    Name = "${var.project_name}-${var.environment}-task-definition"
  }
}

resource "aws_ecs_service" "app" {
  name            = "${var.project_name}-${var.environment}"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn

  desired_count = var.desired_count

  launch_type = "FARGATE"

  platform_version = "LATEST"

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.task_security_group]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = "legacy-api"
    container_port   = var.container_port
  }

  health_check_grace_period_seconds = 60

  enable_ecs_managed_tags = true
  propagate_tags          = "SERVICE"

  depends_on = [
    aws_ecs_task_definition.app
  ]

  tags = {
    Name = "${var.project_name}-${var.environment}-ecs-service"
  }
}