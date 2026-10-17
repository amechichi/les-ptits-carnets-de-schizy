terraform {
    required_version = ">= 1.10"

    backend "s3" {
        bucket       = "terraform-911558392127-eu-west-3-an"
        key          = "ecs/terraform.tfstate" # 1 fichier différent par config terraform pour gérer leur state
        region       = "eu-west-3"
        encrypt      = true
        use_lockfile = true
    }
}

provider "aws" {
    region = "eu-west-3"
}

# Les sous-réseaux du VPC par défaut
data "aws_subnets" "default" {}

# Le security group : ouvre le port 80 (sans vpc_id, il est créé dans le VPC par défaut)
resource "aws_security_group" "app" {
    name = "les-ptits-carnets-de-schizy-sg"

    ingress {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    # C'est quoi egress ? C'est vraiment important de le préciser ?
    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

# Le cluster
resource "aws_ecs_cluster" "app" {
    name = "les-ptits-carnets-de-schizy"
}

# La définition de la tâche
resource "aws_ecs_task_definition" "app" {
    family                   = "les-ptits-carnets-de-schizy"
    requires_compatibilities = ["FARGATE"]
    network_mode             = "awsvpc"
    cpu                      = 256
    memory                   = 512

    container_definitions = jsonencode([{
        name         = "app"
        image        = "ghcr.io/amechichi/les-ptits-carnets-de-schizy:latest"
        essential    = true
        portMappings = [{ containerPort = 80 }]
    }])
}

# Le service
resource "aws_ecs_service" "app" {
    name            = "les-ptits-carnets-de-schizy"
    cluster         = aws_ecs_cluster.app.id
    task_definition = aws_ecs_task_definition.app.arn
    desired_count   = 1
    launch_type     = "FARGATE"

    network_configuration {
        subnets          = data.aws_subnets.default.ids
        security_groups  = [aws_security_group.app.id]
        assign_public_ip = true # nécessaire pour pull l'image sans NAT
    }
}
