terraform {
    required_version = ">= 1.5"
    required_providers {
        aws = { source = "hashicorp/aws", version = "~> 5.0" }
    }

    backend "s3" {
        bucket = "elasticbeanstalk-eu-west-3-911558392127"
        key    = "eb/symfony/terraform.tfstate"
        region = "eu-west-3"
    }
}

provider "aws" {
    region = "eu-west-3"
}

locals {
    app_name = "les-ptits-carnets-de-schizy-tf"

    environments = {
        github = { name = "carnets-de-schizy-github", app_env = "prod" }
        gitlab = { name = "carnets-de-schizy", app_env = "prod" }
    }
}

# --- IAM (à remplacer par des data sources si vous avez déjà ces rôles) ---
resource "aws_iam_role" "ec2" {
    name = "${local.app_name}-eb-ec2"
    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
            Effect    = "Allow"
            Action    = "sts:AssumeRole"
            Principal = { Service = "ec2.amazonaws.com" }
        }]
    })
}

resource "aws_iam_role_policy_attachment" "ec2_web" {
    role       = aws_iam_role.ec2.name
    policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWebTier"
}

resource "aws_iam_instance_profile" "ec2" {
    name = "${local.app_name}-eb-ec2"
    role = aws_iam_role.ec2.name
}

# --- Application ---
resource "aws_elastic_beanstalk_application" "app" {
    name        = local.app_name
    description = "Application Symfony"
}

# Dernière plateforme PHP disponible (utilisée uniquement à la création)
data "aws_elastic_beanstalk_solution_stack" "php" {
    most_recent = true
    name_regex  = "^64bit Amazon Linux 2023 (.*) running PHP 8.5(.*)$"
}

# --- Environnements ---
resource "aws_elastic_beanstalk_environment" "env" {
    for_each = local.environments

    name                = each.value.name
    application         = aws_elastic_beanstalk_application.app.name
    solution_stack_name = data.aws_elastic_beanstalk_solution_stack.php.name

    setting {
        namespace = "aws:autoscaling:launchconfiguration"
        name      = "IamInstanceProfile"
        value     = aws_iam_instance_profile.ec2.name
    }

    setting {
        namespace = "aws:elasticbeanstalk:environment"
        name      = "EnvironmentType"
        value     = "SingleInstance"
    }

    # Symfony : racine web = /public
    setting {
        namespace = "aws:elasticbeanstalk:container:php:phpini"
        name      = "document_root"
        value     = "/public"
    }

    lifecycle {
        # Les CI déploient les versions ; on évite aussi tout remplacement
        # d'environnement lors d'une mise à jour de la plateforme
        ignore_changes = [version_label, solution_stack_name]
    }
}
