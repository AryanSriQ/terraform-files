# Define AWS provider
provider "aws" {
  region = "ap-south-1" # Mumbai region
}

# IAM Role for Lambda functions
resource "aws_iam_role" "main_lambda_execution_role" {
  name = "lambda_execution_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

# Cloudwatch logs acess policy
resource "aws_iam_policy" "lambda_execution_policy" {
  name        = "lambda_execution_policy"
  description = "Policy for Lambda execution role"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

# IAM Policy for Product, Orders Lambda to access RDS
resource "aws_iam_policy" "allow_RDS_lambda_policy" {
  name        = "allow_RDS_lambda_policy"
  description = "IAM policy for product and Orders Lambda function to access RDS"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = [
        "rds-db:connect",
        "rds-db:executeStatement"
      ],
      Resource = "arn:aws:rds-db:region:account-id:dbuser:db-id/products_db"
    }]
  })
}

# IAM policy for main lambda to access SNS
resource "aws_iam_policy" "allow_SNS_lambda_policy" {
  name        = "allow_SNS_lambda_policy"
  description = "IAM policy for main lambda function to access SNS"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = [
        "sns:Publish"
      ],
      Resource = aws_sns_topic.main_sns_topic.arn
    }]
  })
}

# Attach Couldwatch IAM Policy to main_lambda IAM Role
resource "aws_iam_role_policy_attachment" "lambda_role" {
  policy_arn = aws_iam_policy.lambda_execution_policy.arn
  role       = aws_iam_role.main_lambda_execution_role.name
}

# Attach RDS IAM policy to main_lambda IAM Role
resource "aws_iam_role_policy_attachment" "lambda_RDS_role" {
  policy_arn = aws_iam_policy.allow_RDS_lambda_policy.arn
  role       = aws_iam_role.main_lambda_execution_role.name
}

# Attach SNS IAM policy to main_lambda IAM Role
resource "aws_iam_role_policy_attachment" "lambda_SNS_role" {
  policy_arn = aws_iam_policy.allow_SNS_lambda_policy.arn
  role       = aws_iam_role.main_lambda_execution_role.name
}

# API Gateway
resource "aws_api_gateway_rest_api" "api_gateway" {
  name        = "my-api-gateway"
  description = "API Gateway for the application"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = {
    Name = "my-api-gateway"
  }
}

# SNS Topic
resource "aws_sns_topic" "main_sns_topic" {
  name = "main-sns-topic"
}

# SQS Queues
resource "aws_sqs_queue" "products_sqs" {
  name = "product-sqs"
}

resource "aws_sqs_queue" "orders_sqs" {
  name = "orders-sqs"
}

# User Database
resource "aws_db_instance" "user_db" {
  allocated_storage    = 1
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t2.micro"
  username             = "admin"
  password             = "password"
  parameter_group_name = "default.mysql5.7"
  skip_final_snapshot  = true
}

# Product Database
resource "aws_db_instance" "products_db" {
  allocated_storage    = 1
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t2.micro"
  username             = "admin"
  password             = "password"
  parameter_group_name = "default.mysql5.7"
  skip_final_snapshot  = true
}

# Orders Database
resource "aws_db_instance" "orders_db" {
  allocated_storage    = 1                  // gigabytes
  storage_type         = "gp2"              // general-purpose SSD storage type
  engine               = "mysql"            // database engine
  engine_version       = "5.7"              // database engine version
  instance_class       = "db.t2.micro"      // Compute and memory capacity of db instance
  username             = "admin"            // username
  password             = "password"         // password
  parameter_group_name = "default.mysql5.7" // db parameter group associate with this instance
  skip_final_snapshot  = true               // If true, database instance will be deleted without taking a final snapshot
}


# Main Lambda
resource "aws_lambda_function" "main_lambda" {
  function_name = "main-lambda"
  handler       = "index.handler"
  runtime       = "nodejs14.x"
  filename      = "path/to/your/main_lambda.zip" # Replace with Lambda code
  # source_code_hash = filebase64("path/to/your/main_lambda.zip")

  # Attach roles
  role = aws_iam_role.main_lambda_execution_role.arn

  depends_on = [aws_api_gateway_rest_api.api_gateway]

  environment {
    variables = {
      API_GATEWAY   = aws_api_gateway_rest_api.api_gateway.id
      SNS_TOPIC_ARN = aws_sns_topic.main_sns_topic.arn
    }
  }
}
