provider "aws" {
    region = "eu-west-3"
}

# La plateforme PHP à utiliser
data "aws_elastic_beanstalk_solution_stack" "php" {
    most_recent = true
    name_regex  = "^64bit Amazon Linux 2023 (.*) running PHP 8.5(.*)$"
}

# 1. L'application
resource "aws_elastic_beanstalk_application" "app" {
    name = "les-ptits-carnets-de-schizy-tf"
}

# 2. L'environnement
resource "aws_elastic_beanstalk_environment" "env" {
    name                = "carnets-de-schizy"
    application         = aws_elastic_beanstalk_application.app.name
    solution_stack_name = data.aws_elastic_beanstalk_solution_stack.php.name

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
