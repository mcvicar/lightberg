# Specify the provider and access details
provider "aws" {
  region = "eu-west-1"
}

data "aws_iam_policy_document" "policy" {
  statement {
    "Action": "sts:AssumeRole",
    "Principal": {
      "Service": [
        "lambda.amazonaws.com",
        "apigateway.amazonaws.com"
        ]
    },
    "Effect": "Allow",
    "Sid": ""
  }
}

resource "aws_iam_policy" "lightberg" {
  name        = "lightberg"
  description = "lightberg_role"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "lambda:InvokeFunction",
        "s3:GetObject",
        "cloudwatch:PutMetricData",
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

resource "aws_iam_role" "lightberg" {
  name               = "lightberg"
  assume_role_policy = "${data.aws_iam_policy_document.policy.json}"
}

resource "aws_iam_role_policy_attachment" "lightberg-lambdaExecute" {
  role       = "${aws_iam_role.lighberg}"
  policy_arn = "${aws_iam_policy.lightberg.arn}"
}

resource "aws_sns_topic" "lightberg-fanout" {
  name = "lightberg-fanout"
}

resource "aws_sns_topic_subscription" "lightberg-topic-lambda" {
  topic_arn = "${aws_sns_topic.lightberg-fanout.arn}"
  protocol  = "lambda"
  endpoint  = "${aws_lambda_function.lightberg-run.arn}"
}

resource "aws_lambda_function" "lightberg-api" {
  filename         = "lambda/lightberg-api.zip"
  function_name    = "lightberg-api"
  source_code_hash = "${base64sha256(file("lambda/lightberg-api.zip"))}"
  role             = "${aws_iam_role.lightberg.arn}"
  handler          = "index.handler"
  runtime          = "nodejs6.10"
  timeout          = 90

  environment {
    variables = {
      SNS_ARN = "${aws_sns_topic.lightberg-fanout.arn}"
    }
  }
}

resource "aws_lambda_function" "lightberg-run" {
  filename         = "lambda/lightberg-processor.zip"
  function_name    = "lightberg-run"
  source_code_hash = "${base64sha256(file("lambda/lightberg-processor.zip"))}"
  role             = "${aws_iam_role.lightberg.arn}"
  handler          = "index.handler"
  runtime          = "nodejs6.10"
  timeout          = 90
}

resource "aws_lambda_function" "lightberg-report" {
  filename         = "lambda/lightberg-report.zip"
  function_name    = "lightberg-report"
  source_code_hash = "${base64sha256(file("lambda/lightberg-report.zip"))}"
  role             = "${aws_iam_role.lightberg.arn}"
  handler          = "index.handler"
  runtime          = "nodejs6.10"
  timeout          = 90
}

resource "aws_s3_bucket" "lightberg-html-bucket" {
    bucket = "${var.htmlReportBucket}"
}

resource "aws_s3_bucket" "lightberg-json-bucket" {
    bucket = "${var.jsonReportBucket}"
}

resource "aws_lambda_permission" "lightberg-sns" {
    statement_id = "AllowExecutionFromSNS"
    action = "lambda:InvokeFunction"
    function_name = "${aws_lambda_function.lightberg-run.function_name}"
    principal = "sns.amazonaws.com"
    source_arn = "${aws_sns_topic.lightberg-fanout.arn}"
}

resource "aws_sfn_state_machine" "sfn_state_machine" {
  name     = "lightberg"
  role_arn = "${aws_iam_policy_document.policy.arn}"

  definition = <<EOF
  {
    "StartAt": "ApiResponse",
    "States": {
      "ApiResponse":{
        "Type": "Task",
        "Resource":"${aws_lambda_function.lightberg-run.arn}",
        "Next":"summaryReport"
      },
      "summaryReport":{
        "Type": "Task",
        "Resource":"${aws_lambda_function.lightberg-report.arn}",
        "End": true
      }
    }
  }
  EOF
}
