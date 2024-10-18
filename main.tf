terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.67.0"
    }
  }
  backend "kubernetes" {
    secret_suffix = "okteto"
  }
  required_version = ">= 1.2.0"
}

provider "aws" {
  region = var.region
}

variable "lambda_function_name" {
  description = "Name of the Lambda function"
  type        = string
  default     = ""
  validation {
    condition     = length(var.lambda_function_name) > 1
    error_message = "Please specify the name of the Lambda function"
  }
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-west-1"
}

locals {
    timestamp = formatdate("YYYYMMDDhhmmss", timestamp())
    zip_file_name = "/tmp/my_lambda_${local.timestamp}.zip"
}

# IAM role for Lambda
resource "aws_iam_role" "lambda_exec_role" {
  name = "${var.lambda_function_name}-exec-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# attach the official AWS Lambda Execute policy to the role
resource "aws_iam_role_policy_attachment" "lambda_exec_role_attachment" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# zip the code for the Lambda function
data "archive_file" "my_lambda_zip" {
  type = "zip"
  source_file = "app.py"
  output_path = local.zip_file_name
}

# Deploy the Lambda Function
resource "aws_lambda_function" "my_lambda" {
  function_name = var.lambda_function_name
  role          = aws_iam_role.lambda_exec_role.arn
  handler       = "app.lambda_handler"
  runtime       = "python3.9"

  filename = data.archive_file.my_lambda_zip.output_path
  source_code_hash = data.archive_file.my_lambda_zip.output_base64sha256  # Ensures code update detection

  timeout = 100
  memory_size = 128
}

# API Gateway
resource "aws_api_gateway_rest_api" "my_api" {
  name        = "${var.lambda_function_name}-api"
  description = "API Gateway for Lambda"
}

# API Gateway Resource for /hello
resource "aws_api_gateway_resource" "lambda_resource" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  parent_id   = aws_api_gateway_rest_api.my_api.root_resource_id
  path_part   = "hello"
}

# API Gateway Method (GET)
resource "aws_api_gateway_method" "lambda_method" {
  rest_api_id   = aws_api_gateway_rest_api.my_api.id
  resource_id   = aws_api_gateway_resource.lambda_resource.id
  http_method   = "GET"
  authorization = "NONE"
}

# API Gateway Integration (Link to Lambda)
resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  resource_id = aws_api_gateway_resource.lambda_resource.id
  http_method = aws_api_gateway_method.lambda_method.http_method
  type        = "AWS_PROXY"
  integration_http_method = "POST"
  uri         = aws_lambda_function.my_lambda.invoke_arn
}

# API Gateway Deployment
resource "aws_api_gateway_deployment" "lambda_deployment" {
  depends_on = [aws_api_gateway_integration.lambda_integration]
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  stage_name = "Dev"
}

# Lambda permission to allow API Gateway to invoke the function
resource "aws_lambda_permission" "allow_apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.my_lambda.arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.my_api.execution_arn}/*/GET/hello"
}

# Output the API Gateway URL
output "lambda_function_url" {
  description = "URL for the Lambda function"
  value       = "https://${aws_api_gateway_rest_api.my_api.id}.execute-api.${var.region}.amazonaws.com/Dev/hello"
}

