resource "aws_iam_role" "DeleteResolvedItems-Role" {
  name               = "${var.project}-DeleteResolvedItems-Role"
  assume_role_policy = data.aws_iam_policy_document.lambda-assume-role-policy.json
  inline_policy {
    name = "${var.project}-DeleteResolvedItemsLambda-CloudWatch"
    policy = jsonencode({
        Version: "2012-10-17",
        Statement: [
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
                Resource: "${aws_cloudwatch_log_group.DeleteResolvedItems.arn}:*"
            }
        ]
    })
  }
  inline_policy {
    name = "${var.project}-DeleteResolvedItemsLambda-DynamoDB"
    policy = jsonencode({
        Version: "2012-10-17",
        Statement: [
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
                    "dynamodb:UpdateItem",
                    "dynamodb:DeleteItem"
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
  managed_policy_arns = ["arn:aws:iam::aws:policy/AWSSecurityHubReadOnlyAccess"]
}

resource "aws_lambda_function" "DeleteResolvedItems" {
  filename      = "lambdas-code/DeleteResolvedItems.zip"
  function_name = "${var.project}-DeleteResolvedItems"
  role          = aws_iam_role.DeleteResolvedItems-Role.arn
  handler       = "DeleteResolvedItems.lambda_handler"
  source_code_hash = filebase64sha256("lambdas-code/DeleteResolvedItems.zip")
  runtime = "python3.9"
  environment {
    variables = {
      dynamodb_tablename = var.dynamodb_table
    }
  }
}

resource "aws_cloudwatch_event_rule" "DeleteResolvedItems-EventRule" {
  name        = "${var.project}-DeleteResolvedItems-EventRule"
  description = "Daily execution of DeleteResolvedItems Lambda Function "
  is_enabled     = false
  schedule_expression = "cron(0 8 * * ? *)"
}

resource "aws_cloudwatch_event_target" "DeleteResolvedItemsLambda" {
  rule      = aws_cloudwatch_event_rule.DeleteResolvedItems-EventRule.name
  target_id = "SendTo${var.project}DeleteResolvedItemsLambda"
  arn       = aws_lambda_function.DeleteResolvedItems.arn
}

resource "aws_lambda_permission" "allow_eventrule" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.DeleteResolvedItems.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.DeleteResolvedItems-EventRule.arn
}

resource "aws_cloudwatch_log_group" "DeleteResolvedItems" {
  name = "/aws/lambda/${var.project}-DeleteResolvedItems"
}

