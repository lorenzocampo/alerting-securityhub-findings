resource "aws_iam_role" "CheckOldFindings-Role" {
  name               = "${var.project}-CheckOldFindingsLambda-Role"
  assume_role_policy = data.aws_iam_policy_document.lambda-assume-role-policy.json
  inline_policy {
    name = "${var.project}-CheckOldFindingsStateLambda-CloudWatch"
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
                Resource: "${aws_cloudwatch_log_group.CheckOldFindingsState.arn}:*"
            }
        ]
    })
  }
  inline_policy {
    name = "${var.project}-CheckOldFindingsStateLambda-DynamoDB"
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

resource "aws_lambda_function" "CheckOldFindingsState" {
  filename      = "lambdas-code/CheckOldFindingsState.zip"
  function_name = "${var.project}-CheckOldFindingsState"
  role          = aws_iam_role.CheckOldFindings-Role.arn
  handler       = "CheckOldFindingsState.lambda_handler"
  source_code_hash = filebase64sha256("lambdas-code/CheckOldFindingsState.zip")
  runtime = "python3.9"
  timeout = "15"
  environment {
    variables = {
      dynamodb_tablename = var.dynamodb_table
    }
  }
}

resource "aws_cloudwatch_log_group" "CheckOldFindingsState" {
  name = "/aws/lambda/${var.project}-CheckOldFindingsState"
}

