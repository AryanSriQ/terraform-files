# Define AWS provider
provider "aws" {
  region = "ap-south-1" # Mumbai region
}

# IAM Role for Lambda functions
resource "aws_iam_role" "lambda_role" {
  name               = "lambda-role"
  assume_role_policy = data.aws_iam_policy_document.assume
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

# Main Lambda
# resource "aws_lambda_function" "main_lambda" {
#   function_name = "main-lambda"
#   handler       = "index.handler"
#   runtime       = "nodejs14.x"
#   filename      = "path/to/your/main_lambda.zip" # Replace with Lambda code
#   # source_code_hash = filebase64("path/to/your/main_lambda.zip")

#   role = [aws_iam_role.lambda_role.name, aws_iam_role.allow_RDS_lambda_policy.name, aws_iam_role.allow_SNS_lambda_policy.name]

#   depends_on = [aws_api_gateway_rest_api.api_gateway]

#   environment {
#     variables = {
#       API_GATEWAY   = aws_api_gateway_rest_api.api_gateway.id
#       SNS_TOPIC_ARN = aws_sns_topic.main_sns_topic.arn
#     }
#   }
#   #   lifecycle {
#   #     ignore_changes = [
#   #       filename
#   #     ]
#   #   }
# }

# # User Database
# resource "aws_db_instance" "user_db" {
#   allocated_storage    = 1
#   storage_type         = "gp2"
#   engine               = "mysql"
#   engine_version       = "5.7"
#   instance_class       = "db.t2.micro"
#   username             = "admin"
#   password             = "password"
#   parameter_group_name = "default.mysql5.7"
#   skip_final_snapshot  = true
# }

# # Product Database
# resource "aws_db_instance" "products_db" {
#   allocated_storage    = 1
#   storage_type         = "gp2"
#   engine               = "mysql"
#   engine_version       = "5.7"
#   instance_class       = "db.t2.micro"
#   username             = "admin"
#   password             = "password"
#   parameter_group_name = "default.mysql5.7"
#   skip_final_snapshot  = true
# }

# # Orders Database
# resource "aws_db_instance" "orders_db" {
#   allocated_storage    = 1                  // gigabytes
#   storage_type         = "gp2"              // general-purpose SSD storage type
#   engine               = "mysql"            // database engine
#   engine_version       = "5.7"              // database engine version
#   instance_class       = "db.t2.micro"      // Compute and memory capacity of db instance
#   username             = "admin"            // username
#   password             = "password"         // password
#   parameter_group_name = "default.mysql5.7" // db parameter group associate with this instance
#   skip_final_snapshot  = true               // If true, database instance will be deleted without taking a final snapshot
# }

# # SNS Topic
# resource "aws_sns_topic" "main_sns_topic" {
#   name = "main-sns-topic"
# }

# # SQS Queues
# resource "aws_sqs_queue" "products_sqs" {
#   name = "product-sqs"
# }

# resource "aws_sqs_queue" "orders_sqs" {
#   name = "orders-sqs"
# }

# # Lambda for Product
# resource "aws_lambda_function" "products_lambda" {
#   function_name = "products_lambda_function"
#   handler       = "index.handler"
#   runtime       = "nodejs14.x"
#   memory_size   = 256
#   timeout       = 5
#   role          = [aws_iam_role.lambda_role.arn, aws_iam_role.allow_RDS_lambda_policy.name]

#   filename = "path/to/your/products_lambda.zip"
#   # source_code_hash = filebase64sha256("path/to/your/products_lambda.zip")

#   depends_on = [aws_sns_topic.main_sns_topic, aws_sqs_queue.products_sqs]

#   environment {
#     variables = {
#       TOPIC_ARN = aws_sns_topic.main_sns_topic.arn
#       QUEUE_ARN = aws_sqs_queue.products_sqs.arn
#     }
#   }
# }

# # Lambda for Orders
# resource "aws_lambda_function" "orders_lambda" {
#   function_name = "orders_lambda_function"
#   handler       = "index.handler"
#   runtime       = "nodejs14.x"
#   memory_size   = 256
#   timeout       = 5
#   role          = [aws_iam_role.lambda_role.arn, aws_iam_role.allow_RDS_lambda_policy.name]

#   filename = "path/to/your/orders_lambda.zip"
#   # source_code_hash = filebase64sha256("path/to/your/orders_lambda.zip")

#   depends_on = [aws_sns_topic.main_sns_topic, aws_sqs_queue.orders_sqs]

#   environment {
#     variables = {
#       TOPIC_ARN = aws_sns_topic.main_sns_topic.arn
#       QUEUE_ARN = aws_sqs_queue.orders_sqs.arn
#     }
#   }
# }

# ################# Define connections #####################

# # Auth > API gateway
# # Implement authentication configurations as needed

# # API gateway > Main Lambda
# # Connect API Gateway to Main Lambda
# resource "aws_api_gateway_resource" "main_resource" {
#   rest_api_id = aws_api_gateway_rest_api.api_gateway.id
#   parent_id   = aws_api_gateway_rest_api.api_gateway.root_resource_id
#   path_part   = "main"
# }

# # Defined a single POST method
# resource "aws_api_gateway_method" "main_method" {
#   rest_api_id   = aws_api_gateway_rest_api.api_gateway.id
#   resource_id   = aws_api_gateway_resource.main_resource.id
#   http_method   = "POST"
#   authorization = "NONE"
# }

# resource "aws_api_gateway_integration" "main_integration" {
#   rest_api_id             = aws_api_gateway_rest_api.api_gateway.id
#   resource_id             = aws_api_gateway_resource.main_resource.id
#   http_method             = aws_api_gateway_method.main_method.http_method
#   integration_http_method = "POST"
#   type                    = "AWS_PROXY"
#   uri                     = aws_lambda_function.main_lambda.invoke_arn
# }

# # main lambda > SNS
# # resource "aws_api_gateway_integration_response" "main_integration_response" {
# #   rest_api_id = aws_api_gateway_rest_api.api_gateway.id
# #   resource_id = aws_api_gateway_resource.main_resource.id
# #   http_method = aws_api_gateway_method.main_method.http_method
# #   status_code = aws_api_gateway_method_response.main_method_response.status_code

# #   response_parameters = {
# #     "method.response.header.Access-Control-Allow-Origin" = "'*'"
# #   }

# #   response_templates = {
# #     "application/json" = ""
# #   }

# #   depends_on = [aws_api_gateway_method_response.main_method_response]
# # }

# # connect main lambda to sns and allow sns to run when a certain endpoint is triggered in the main lambda api
# resource "aws_lambda_permission" "sns" {
#   statement_id  = "AllowExecutionFromSNS"
#   action        = "lambda:InvokeFunction"
#   function_name = aws_lambda_function.main_lambda.function_name
#   principal     = "sns.amazonaws.com"
#   source_arn    = aws_sns_topic.main_sns_topic.arn
# }

# # SNS > SQS Group
# resource "aws_sns_topic_subscription" "sns_to_products_sqs_subscription" {
#   topic_arn = aws_sns_topic.main_sns_topic.arn
#   protocol  = "sqs"
#   endpoint  = aws_sqs_queue.products_sqs.arn
# }

# resource "aws_sns_topic_subscription" "sns_to_orders_sqs_subscription" {
#   topic_arn = aws_sns_topic.main_sns_topic.arn
#   protocol  = "sqs"
#   endpoint  = aws_sqs_queue.orders_sqs.arn
# }

# # Product SQS > Product Lambda
# resource "aws_lambda_event_source_mapping" "products_lambda_event_source_mapping" {
#   event_source_arn  = aws_sqs_queue.products_sqs.arn
#   function_name     = aws_lambda_function.products_lambda.products_lambda_function
#   starting_position = "LATEST"
# }

# # Orders SQS > Orders Lambda
# resource "aws_lambda_event_source_mapping" "orders_lambda_event_source_mapping" {
#   event_source_arn  = aws_sqs_queue.orders_sqs.arn
#   function_name     = aws_lambda_function.orders_lambda.orders_lambda_function
#   starting_position = "LATEST"
# }

# # Product Lambda > Product Database
# # resource "aws_lambda_permission" "products_lambda_db_permission" {
# #   statement_id  = "AllowExecutionFromSQS"
# #   action        = "lambda:InvokeFunction"
# #   function_name = aws_lambda_function.products_lambda.function_name
# #   principal     = "sqs.amazonaws.com"
# #   source_arn    = aws_sqs_queue.products_sqs.arn
# # }

# # Orders Lambda > Orders Database
# # resource "aws_lambda_permission" "orders_lambda_db_permission" {
# #   statement_id  = "AllowExecutionFromSQS"
# #   action        = "lambda:InvokeFunction"
# #   function_name = aws_lambda_function.orders_lambda.function_name
# #   principal     = "sqs.amazonaws.com"
# #   source_arn    = aws_sqs_queue.orders_sqs.arn
# # }
