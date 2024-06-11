terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.51.1"
    }
  }
}

provider "aws" {
  region = var.region
}

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = [ "sts:AssumeRole" ]
    principals {
      type = "Service"
      identifiers = [ "sagemaker.amazonaws.com" ]
    }
  }
}

resource "aws_iam_role" "foo" {
  name = "sagemaker-role"
  path = "/"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "foo" {
  statement {
    effect = "Allow"
    actions = [
      "sagemaker:*",
      "cloudwatch:PutMetricData",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:CreateLogGroup",
      "logs:DescribeLogStreams",
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "foo" {
  name        = "sagemaker-policy"
  description = "Allow Sagemaker to create model"
  policy      = data.aws_iam_policy_document.foo.json
}

resource "aws_iam_role_policy_attachment" "foo" {
  role       = aws_iam_role.foo.name
  policy_arn = aws_iam_policy.foo.arn
}

resource "aws_sagemaker_model" "foo" {
  name              = "car-height-detection"
  execution_role_arn = aws_iam_role.foo.arn

  primary_container {
    image = "${data.aws_caller_identity.current.account_id}.dkr.ecr.ap-northeast-2.amazonaws.com/car-height-detection:latest"
  }

  tags = {
    foo = "bar"
  }
}

resource "aws_sagemaker_endpoint_configuration" "foo" {
  name = "car-height-detection"

  production_variants {
    variant_name           = "variant-1"
    model_name             = aws_sagemaker_model.foo.name
    initial_instance_count = 1
    instance_type          = "ml.m4.xlarge"
    initial_variant_weight = 1
  }

  tags = {
    foo = "bar"
  }
}

resource "aws_sagemaker_endpoint" "foo" {
  name = "car-height-detection"
  endpoint_config_name = aws_sagemaker_endpoint_configuration.foo.name

  tags = {
    foo = "bar"
  }
}
