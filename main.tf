terraform {
    required_version = ">= 1.10"

    backend "s3" {
        bucket       = "terraform-911558392127-eu-west-3-an"
        key          = "tfstate/terraform.tfstate"
        region       = "eu-west-3"
        encrypt      = true
        use_lockfile = true
    }
}

provider "aws" {
    region = "eu-west-3"
}

resource "aws_s3_bucket" "eb" {
    bucket        = "elasticbeanstalk-eu-west-3-911558392127"
    force_destroy = true # bypass la règle qui interdit la suppression
}

# La plateforme PHP à utiliser
data "aws_elastic_beanstalk_solution_stack" "php" {
    most_recent = true
    name_regex  = "^64bit Amazon Linux 2023 (.*) running PHP 8.5(.*)$"
}

# L'application
resource "aws_elastic_beanstalk_application" "app" {
    name = "les-ptits-carnets-de-schizy"
}

# L'environnement
resource "aws_elastic_beanstalk_environment" "env" {
    name                = "les-ptits-carnets-de-schizy-env"
    application         = aws_elastic_beanstalk_application.app.name
    solution_stack_name = data.aws_elastic_beanstalk_solution_stack.php.name
    depends_on = [aws_s3_bucket.eb] # Pour créer le S3 avant l'app puis pour le détruire après l'app

    setting {
        namespace = "aws:elasticbeanstalk:environment"
        name      = "EnvironmentType"
        value     = "SingleInstance"
    }

    setting {
        namespace = "aws:autoscaling:launchconfiguration"
        name      = "IamInstanceProfile"
        value     = "aws-elasticbeanstalk-ec2-role"
    }

    setting {
        namespace = "aws:elasticbeanstalk:container:php:phpini"
        name      = "document_root"
        value     = "/public"
    }
}
