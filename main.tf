# Creación de la VPC- Se crean dos subredes en la misma zona de disponibidad

resource "aws_vpc" "ecs_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "ecs-vpc"
  }
}

resource "aws_subnet" "public_subnet_1" {
  vpc_id     = aws_vpc.ecs_vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"  
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id     = aws_vpc.ecs_vpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-1a"  
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.ecs_vpc.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.ecs_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public-route-table"
  }
}

resource "aws_route_table_association" "subnet_1_association" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "subnet_2_association" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public.id
}
# Creación del cluster donde se ejecutarán las tareas

resource "aws_ecs_cluster" "ecs_cluster" {
  name = "my-ecs-cluster"
}

# Definicion de la tarea

resource "aws_ecs_task_definition" "task" {
  family                   = "nginx-task"
  requires_compatibilities = ["EC2"]
  network_mode             = "bridge"
  container_definitions = <<DEFINITION
[
  {
    "name": "nginx",
    "image": "nginx:latest",
    "cpu": 256,
    "memory": 512,
    "essential": true,
    "portMappings": [
      {
        "containerPort": 80,
        "hostPort": 80
      }
    ]
  }
]
DEFINITION
}


#Definición de la intancia EC2 para ECS y el grupo de autoscaling

resource "aws_launch_configuration" "ecs_instance" {
  name          = "ecs-instance"
  image_id      = "ami-0e86e20dae9224db8"  # AMI optimizada para ECS
  instance_type = "t2.micro"
  
  user_data = <<-EOF
              #!/bin/bash
              echo ECS_CLUSTER=${aws_ecs_cluster.ecs_cluster.name} >> /etc/ecs/ecs.config
            EOF
  
  security_groups = [aws_security_group.ecs_instance_sg.id]
  associate_public_ip_address = true
  
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "ecs_instances" {
  launch_configuration = aws_launch_configuration.ecs_instance.id
  min_size             = 1
  max_size             = 3
  desired_capacity     = 2
  vpc_zone_identifier  = aws_subnet.public_subnet_1.id

  tag {
    key                 = "Name"
    value               = "ecs-instance"
    propagate_at_launch = true
  }
}
# Servicio

resource "aws_ecs_service" "ecs_service" {
  name            = "nginx-service"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.task.arn
  desired_count   = 2
  launch_type     = "EC2"
  deployment_maximum_percent = 200
  deployment_minimum_healthy_percent = 50
}

# Security group 

resource "aws_security_group" "ecs_instance_sg" {
  name        = "ecs-instance-sg"
  description = "Allow HTTP traffic"
  vpc_id      = aws_vpc.ecs_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ecs-instance-sg"
  }
}



