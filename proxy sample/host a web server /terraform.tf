# Configure the AWS Provider
provider "aws" {
  region = "your-aws-region"  # e.g., "us-west-2"
}

# -------------------------------------------------------------------
# Option 1:  Using ECS/Fargate (Recommended for Scalability)
# -------------------------------------------------------------------

# Create an ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "your-cluster-name"
}

# Create an ECS Task Definition (specifies the Docker container)
resource "aws_ecs_task_definition" "nginx" {
  family             = "nginx-task"
  network_mode       = "awsvpc" # Required for Fargate
  requires_compatibilities = ["FARGATE"] # Use Fargate
  cpu                = "256"   # Adjust as needed
  memory             = "512"   # Adjust as needed
  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn  # IAM role for ECS to access resources

  container_definitions = jsonencode([
    {
      name      = "nginx-container",
      image     = "nginx:latest", # Or your custom image
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
    }
  ])
}

# Create an IAM role for ECS task execution
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecs-task-execution-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        },
        Effect = "Allow",
        Sid = ""
      }
    ]
  })
}

# Optionally, create an ALB (Application Load Balancer) to distribute traffic
resource "aws_lb" "alb" {
  name               = "your-alb-name"
  internal           = false  # Make it public
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public.*.id # Replace with your public subnets

  enable_deletion_protection = false
}

# Create a Target Group for the ECS service
resource "aws_lb_target_group" "nginx" {
  name        = "nginx-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = "your-vpc-id" # Replace with your VPC ID
  target_type = "ip" # Required for Fargate
}

# Create a Listener for the ALB
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nginx.arn
  }
}

# Create an ECS Service (runs and maintains the containers)
resource "aws_ecs_service" "nginx" {
  name            = "nginx-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.nginx.arn
  desired_count   = 1       # Number of containers to run
  launch_type     = "FARGATE" # Use Fargate

  network_configuration {
    subnets         = aws_subnet.public.*.id  # Replace with your public subnets
    security_groups = [aws_security_group.ecs.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.nginx.arn
    container_name   = "nginx-container"
    container_port   = 80
  }

  depends_on = [aws_lb_listener.http] # Ensure the listener is created first
}

# -------------------------------------------------------------------
# Option 2: Deploying directly on an EC2 Instance (Simpler, less scalable)
# -------------------------------------------------------------------
# Requires creating:
# - An EC2 instance
# - Security Group to allow traffic
# - User data to install Docker and run the container (using remote-exec or cloud-init)
# See the search results for examples (but ECS/Fargate is generally preferred)

# Output the ALB's DNS name (or the EC2 instance's public IP if not using a load balancer)
output "alb_dns_name" {
  value = aws_lb.alb.dns_name
}
