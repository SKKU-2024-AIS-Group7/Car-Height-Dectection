terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.51.1"
    }
  }

  backend "s3" {
    bucket         = "car-height-detection-tfstate-storage"
    key            = "terraform/terraform.tfstate"
    region         = "ap-northeast-2"
    encrypt        = true
    dynamodb_table = "car-height-detection-tfstate-lock"
  }
}

provider "aws" {
  region = var.region
}

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "model_bucket" {
  bucket = "car-height-detection-model"
}

resource "aws_s3_object" "model_artifact" {
  bucket = aws_s3_bucket.model_bucket.bucket
  key    = "model/model.tar.gz"
  source = "${path.module}/model.tar.gz"
  etag   = filemd5("${path.module}/model.tar.gz")
}

resource "aws_iam_role" "sagemaker_execution_role" {
  name = "sagemaker-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "sagemaker.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "sagemaker_policy" {
  role = aws_iam_role.sagemaker_execution_role.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:*",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "s3:GetObject",
          "sagemaker:*",
        ]
        Resource = "*"
      }
    ]
  })
}


resource "aws_sagemaker_model" "pytorch_model" {
  name               = "pytorch-model"
  execution_role_arn = aws_iam_role.sagemaker_execution_role.arn

  primary_container {
    image          = "763104351884.dkr.ecr.${var.region}.amazonaws.com/pytorch-inference:1.8.1-cpu-py36-ubuntu18.04"
    model_data_url = "s3://${aws_s3_bucket.model_bucket.bucket}/model/model.tar.gz"
    environment = {
      SAGEMAKER_PROGRAM                   = "inference.py"
      SAGEMAKER_SUBMIT_DIRECTORY          = "/opt/ml/model"
      SAGEMAKER_ENABLE_CLOUDWATCH_METRICS = "true"
      SAGEMAKER_REGION                    = var.region
    }
  }
}

resource "aws_sagemaker_endpoint_configuration" "pytorch_model_endpoint_config" {
  name = "pytorch-model-endpoint-config"

  data_capture_config {
    enable_capture              = true
    destination_s3_uri          = "s3://${aws_s3_bucket.model_bucket.bucket}/capture/"
    initial_sampling_percentage = 100

    capture_options {
      capture_mode = "Input"
    }

    capture_options {
      capture_mode = "Output"
    }

    capture_content_type_header {
      csv_content_types  = ["text/csv"]
      json_content_types = ["application/json"]
    }
  }

  production_variants {
    variant_name           = "AllTraffic"
    model_name             = aws_sagemaker_model.pytorch_model.name
    initial_instance_count = 1
    instance_type          = "ml.m4.xlarge"
  }
}

resource "aws_sagemaker_endpoint" "pytorch_model_endpoint" {
  name                 = "pytorch-model-endpoint"
  endpoint_config_name = aws_sagemaker_endpoint_configuration.pytorch_model_endpoint_config.name
}
