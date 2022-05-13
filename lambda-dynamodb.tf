resource "aws_iam_role" "DynamoDB-Role" {
  name               = "${var.project}-DynamoDB-Role"
  assume_role_policy = data.aws_iam_policy_document.lambda-assume-role-policy.json
  inline_policy {
    name = "${var.project}-DynamoDBLambda-CloudWatch"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
            Effect: "Allow",
            Action: "logs:CreateLogGroup",
            Resource: "arn:aws:logs:${var.region}:${var.account_id}:*"
        },
        {
            Effect: "Allow",
            Action: [
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            Resource: "${aws_cloudwatch_log_group.DynamoDB.arn}:*"
        }
      ]
    })
  }
  inline_policy {
    name = "${var.project}-DynamoDBLambda-DynamoDB"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
            Sid: "ReadWriteTable",
            Effect: "Allow",
            Action: [
                "dynamodb:BatchGetItem",
                "dynamodb:GetItem",
                "dynamodb:Query",
                "dynamodb:Scan",
                "dynamodb:BatchWriteItem",
                "dynamodb:PutItem",
                "dynamodb:UpdateItem"
            ],
            Resource: "arn:aws:dynamodb:${var.region}:${var.account_id}:table/${var.dynamodb_table}"
        },
        {
            Sid: "GetStreamRecords",
            Effect: "Allow",
            Action: "dynamodb:GetRecords",
            Resource: "arn:aws:dynamodb:${var.region}:${var.account_id}:table/${var.dynamodb_table}/stream/* "
        }
      ]
    })
  }
}

resource "aws_lambda_function" "DynamoDB" {
  filename      = "lambdas-code/DynamoDB.zip"
  function_name = "${var.project}-DynamoDB"
  role          = aws_iam_role.DynamoDB-Role.arn
  handler       = "DynamoDB.lambda_handler"
  source_code_hash = filebase64sha256("lambdas-code/DynamoDB.zip")
  runtime = "python3.9"
  timeout = "15"
  environment {
    variables = {
      dynamodb_tablename = var.dynamodb_table
    }
  }
}

resource "aws_cloudwatch_log_group" "DynamoDB" {
  name = "/aws/lambda/${var.project}-DynamoDB"
}

