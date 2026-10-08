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

# Le bucket S3 d'Elastic Beanstalk
resource "aws_s3_bucket" "eb" {
    bucket        = "elasticbeanstalk-eu-west-3-911558392127"
    force_destroy = true # bypass la règle qui interdit la suppression
}

# L'Object Ownership du S3 pour permettre à Elastic Beanstalk de posséder les objets qu'il crée dans le bucket
resource "aws_s3_bucket_ownership_controls" "eb" {
    bucket = aws_s3_bucket.eb.id
    rule { object_ownership = "BucketOwnerPreferred" }
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

    # Pour créer le S3 (avec la bonne permission) avant l'app
    depends_on = [aws_s3_bucket.eb, aws_s3_bucket_ownership_controls.eb,]

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
