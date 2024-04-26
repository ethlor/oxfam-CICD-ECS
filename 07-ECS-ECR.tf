# ECR REPOSITORY
resource "aws_ecr_repository" "ecr-repo-backend" {
  name = "backend"
}

resource "aws_ecr_repository" "ecr-repo-frontend" {
  name = "frontend"
}

# ECS CLUSTER
resource "aws_ecs_cluster" "ecs-cluster" {
  name = "oxfamcluster"
}

# TASK DEFINITION
resource "aws_ecs_task_definition" "task" {
  family                   = "HTTPserver"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 1024
  memory                   = 2048
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name   = "oxfam-container"
      image  = "${var.uri_repo}/frontend:latest" #URI
      cpu    = 256
      memory = 512
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
    },
    {
      name   = "oxfam_backend_container"
      image  = "${var.uri_repo}/backend:latest"
      cpu    = 256
      memory = 512
      portMappings = [
        {
          containerPort = 8000
          hostPort      = 8000
        }
      ]
    }
  ])
}

# ECS SERVICE
resource "aws_ecs_service" "svc" {
  name            = "oxfam-Service"
  cluster         = aws_ecs_cluster.ecs-cluster.id
  task_definition = aws_ecs_task_definition.task.id
  desired_count   = 1
  launch_type     = "FARGATE"


  network_configuration {
    subnets          = ["${aws_subnet.pub-subnets[0].id}", "${aws_subnet.pub-subnets[1].id}"]
    security_groups  = ["${aws_security_group.sg1.id}"]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.tg-group.arn
    container_name   = "oxfam-container"
    container_port   = "80"
  }
}