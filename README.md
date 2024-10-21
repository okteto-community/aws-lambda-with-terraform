# Deploying AWS Lambda Functions on Okteto with Terraform

This guide and sample app are meant to show how you can deploy [AWS Lambda Functions](https://docs.aws.amazon.com/lambda/latest/dg/welcome.html) as [External Resources](https://www.okteto.com/docs/tutorials/external-resources/) on [Okteto](https://www.okteto.com/) with the help of [Terraform](https://www.terraform.io/).

If you'd prefer that method, we also have a sample on how to do this with the [AWS SAM CLI](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/what-is-sam-overview.html) on [our website](https://www.okteto.com/docs/tutorials/aws-lambda/).

This sample deploys a Lambda function that’s a simple Python function, which is triggered via an HTTP request. The function is exposed via [API Gateway](https://aws.amazon.com/api-gateway/), which serves as the entry point for requests. The deployed function listens at the `/hello` endpoint and responds with a message: `"Hello from Lambda!"`.

## Steps To Run This

1.  Configure [Cloud Credentials](https://www.okteto.com/docs/admin/cloud-credentials/aws-cloud-credentials/) so that Okteto can create resources in your AWS account. Make sure to give the following permissions to the [IAM role you create](https://www.okteto.com/docs/admin/cloud-credentials/aws-cloud-credentials/#step-2-create-the-iam-role-and-grant-access-to-s3) during the Cloud Credentials setup. This will enable every developer on your team to create AWS Lambda functions without requiring personal credentials.

    - AWSCloudFormationFullAccess
    - IAMFullAccess
    - AWSLambda_FullAccess
    - AmazonAPIGatewayAdministrator
    - AmazonS3FullAccess

1.  Run `okteto deploy` to spin up your development environment as part of which the lambda function and all the necessary resources would automatically be created for your developers.

## How It Works

After configuring [Cloud Credentials](https://www.okteto.com/docs/admin/cloud-credentials/aws-cloud-credentials/), Okteto takes care of the authentication with AWS required by Terraform to create the AWS Lambda Functions in the `deploy` section of your manifest. In the Okteto Manifest, we then run the Terraform commands to create the Lambda Function and the additional necessary resources it needs.

In the `main.tf` file, we define the AWS resources that work together to deploy and expose a Lambda function using API Gateway. Here is a summary of each resource and its role, which you can use to build similar infrastructure for your own Lambda-based applications:

1. IAM Role for Lambda
   Resource: `aws_iam_role`
   Purpose: This defines the permissions for the Lambda function, allowing it to run and perform necessary actions, like writing logs to CloudWatch. The `AWSLambdaBasicExecutionRole` policy is used here to give basic execution permissions.
1. Lambda Function
   Resource: `aws_lambda_function`
   Purpose: This is where your function code (e.g., app.py) runs. Lambda automatically scales your function and handles execution when triggered by events (like an HTTP request).
1. API Gateway
   Resource: `aws_api_gateway_rest_api`
   Purpose: API Gateway exposes your Lambda function over HTTP. It creates an API that external clients can use to trigger your Lambda function via an HTTP request.
1. API Gateway Resource and Method
   Resource: `aws_api_gateway_resource`, `aws_api_gateway_method`
   Purpose: These resources define the API endpoints (e.g., /hello) and the HTTP methods (e.g., GET) that trigger the Lambda function.

1. API Gateway Integration
   Resource: `aws_api_gateway_integration`
   Purpose: This ties the API Gateway to your Lambda function, so when a request is sent to /hello, the Lambda function is invoked.
1. API Gateway Deployment
   Resource: `aws_api_gateway_deployment`
   Purpose: This "deploys" your API Gateway to a specific stage (in this case, Dev), making it live and accessible to external users.
1. Lambda Permission for API Gateway
   Resource: `aws_lambda_permission`
   Purpose: This grants API Gateway permission to invoke your Lambda function. Without this, API Gateway wouldn't have the rights to trigger the Lambda.
1. Output (API Gateway URL)
   Resource: `output`
   Purpose: This provides the URL that you can use to access the Lambda function via API Gateway.

## Benefits of Using Okteto and Terraform:

1. Okteto allows you to deploy and manage serverless functions as external resources, providing a seamless development experience. You don't have to configure access to an AWS account for each developer and manage hacky solutions to provision Lambda Functions for developers when they need them during development.

1. Okteto gives you full control of the lifecycle of the AWS resources. When developers on your team delete the dev environment (or [Okteto's Garbage Collector](https://www.okteto.com/docs/admin/cleanup/) does it automatically for you after it's not in use), the AWS resources are also cleaned up!

1. Terraform gives you full control over the AWS resources you want to provision, making it a versatile tool for defining infrastructure as code.

1. By combining Okteto with Terraform, developers can easily develop applications that require Lambda functions without needing to configure the AWS infrastructure manually.
