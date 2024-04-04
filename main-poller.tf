locals {
  service_security_groups = ["${aws_security_group.service_security_group.id}"]
}

resource "aws_default_vpc" "default_vpc" {
}

resource "aws_default_subnet" "default_subnet_a" {
  availability_zone = "ca-central-1a"
}

resource "aws_default_subnet" "default_subnet_b" {
  availability_zone = "ca-central-1b"
}

resource "aws_security_group" "load_balancer_security_group" {
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow traffic in from all sources
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_alb" "application_load_balancer" {
  name               = "dsb-blogging-assistant-ecs-lb"
  load_balancer_type = "application"
  subnets = [
    aws_default_subnet.default_subnet_a.id,
    aws_default_subnet.default_subnet_b.id
  ]

  security_groups = [
    aws_security_group.load_balancer_security_group.id
  ]
}

resource "aws_lb_target_group" "target_group" {
  name        = "dsb-ba-target-group"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_default_vpc.default_vpc.id # default VPC

  health_check {
    path = "/test"
  }
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_alb.application_load_balancer.arn #  load balancer
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group.arn # target group
  }
}

resource "aws_security_group" "service_security_group" {
  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.load_balancer_security_group.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Log Configuration
resource "aws_cloudwatch_log_group" "default_poller_lg" {
  name = "dsb-blogging-assistant-ecr-log-group"
}

# ECR Repository
data "aws_ecr_image" "poller_repo_lookup" {
  repository_name = aws_ecr_repository.poller_repo.name
  most_recent     = true
}
resource "aws_ecr_repository" "poller_repo" {
  name         = "dsb-blogging-assistant-poller-image"
  force_delete = true
}

resource "aws_ecs_task_definition" "poller_task" {
  family                   = "poller-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256" # CPU units for the task
  memory                   = "512" # Memory for the task in MiB
  execution_role_arn       = "arn:aws:iam::976556613810:role/ecsTaskExecutionRole"

  container_definitions = jsonencode([
    {
      name  = "dsb-ba-poller-container"
      image = "${aws_ecr_repository.poller_repo.repository_url}:latest"
      portMappings = [
        {
          containerPort = 80 # Replace with the port your app listens on
          hostPort      = 80 # Replace if you want to map to a different host port
        }
      ]
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          awslogs-group         = "${aws_cloudwatch_log_group.default_poller_lg.name}"
          awslogs-region        = "${data.aws_region.current.name}"
          awslogs-stream-prefix = "streaming"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "poller_service" {
  name            = "dsb-ba-poller-service"
  cluster         = aws_ecs_cluster.default_ecs_cluster.id
  task_definition = aws_ecs_task_definition.poller_task.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  force_new_deployment = true

  load_balancer {
    target_group_arn = aws_lb_target_group.target_group.arn # Reference the target group
    container_name   = "dsb-ba-poller-container"            # Must always align with the name of the container
    container_port   = 80                                   # Specify the container port
  }

  network_configuration {
    subnets          = [aws_default_subnet.default_subnet_b.id, aws_default_subnet.default_subnet_a.id]
    security_groups  = [aws_security_group.service_security_group.id]
    assign_public_ip = true
  }

  depends_on = [aws_ecs_task_definition.poller_task]
}

resource "aws_ecs_cluster" "default_ecs_cluster" {
  name = "dsb-blogging-assistant-cluster"
}

output "app_url" {
  value = aws_alb.application_load_balancer.dns_name
}

