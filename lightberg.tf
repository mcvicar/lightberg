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

resource "aws_iam_role" "lightberg" {
  name               = "lightberg"
  assume_role_policy = "${data.aws_iam_policy_document.policy.json}"
}

resource "aws_lambda_function" "lightberg-api" {
  filename         = "lambda/lightberg-api.zip"
  function_name    = "lightberg-api"
  source_code_hash = "${base64sha256(file("lambda/lightberg-api.zip"))}"
  role             = "${aws_iam_role.lightberg.arn}"
  handler          = "index.handler"
  runtime          = "nodejs6.10"
  timeout          = 90
}

resource "aws_lambda_function" "lightberg-run" {
  filename         = "lambda/lightberg-run.zip"
  function_name    = "lightberg-run"
  source_code_hash = "${base64sha256(file("lambda/lightberg-run.zip"))}"
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
