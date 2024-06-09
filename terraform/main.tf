terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region     = "us-east-1"
}

resource "aws_ecs_cluster" "sk_devops_cluster" {
  name = "sk-devops-cluster"
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_ecr_repository" "sk_devops_repo" {
  name = "sk-devops-repo"
}

resource "aws_ecs_task_definition" "sk_devops_task" {
  family                   = "sk-devops-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  cpu                      = "256"
  memory                   = "512"

  container_definitions = jsonencode([
    {
      name      = "sk-devops-app"
      image     = "${aws_ecr_repository.sk_devops_repo.repository_url}:latest"
      essential = true

      portMappings = [
        {
          containerPort = 3000
          hostPort      = 3000
        }
      ]
    }
  ])
}

resource "aws_lb" "sk_devops_lb" {
  name               = "sk-devops-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sk_devops_sg.id]
  subnets            = var.subnet_ids
}

resource "aws_lb_target_group" "sk_devops_tg" {
  name        = "sk-devops-tg"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"
}

resource "aws_lb_listener" "sk_devops_listener" {
  load_balancer_arn = aws_lb.sk_devops_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.sk_devops_tg.arn
  }
}

resource "aws_ecs_service" "sk_devops_service" {
  name            = "sk-devops-service"
  cluster         = aws_ecs_cluster.sk_devops_cluster.id
  task_definition = aws_ecs_task_definition.sk_devops_task.arn
  desired_count   = 1

  launch_type = "FARGATE"

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = [aws_security_group.sk_devops_sg.id]
    assign_public_ip = true  # Ensure public IP assignment for internet access
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.sk_devops_tg.arn
    container_name   = "sk-devops-app"
    container_port   = 3000
  }
}

resource "aws_security_group" "sk_devops_sg" {
  name_prefix = "sk-devops-sg"

  ingress {
    from_port   = 3000
    to_port     = 3000
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
