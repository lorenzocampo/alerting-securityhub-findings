resource "aws_iam_role" "ParseHtmlMail-Role" {
  name               = "${var.project}-ParseHtmlMail-Role"
  assume_role_policy = data.aws_iam_policy_document.lambda-assume-role-policy.json
  inline_policy {
    name = "${var.project}-ParseHtmlMail-CloudWatch"
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
            Resource: "${aws_cloudwatch_log_group.ParseHtmlMail.arn}:*"
        }
      ]
    })
  }
  inline_policy {
    name = "${var.project}-ParseHtmlMail-SES"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
            Effect: "Allow",
            Action: [
                "ses:SendEmail",
                "ses:SendRawEmail"
            ],
            Resource: "*"
        }
      ]
    })
  }
}

resource "aws_lambda_function" "ParseHtmlMail" {
  filename      = "lambdas-code/ParseHtmlMail.zip"
  function_name = "${var.project}-ParseHtmlMail"
  role          = aws_iam_role.ParseHtmlMail-Role.arn
  handler       = "ParseHtmlMail.lambda_handler"
  source_code_hash = filebase64sha256("lambdas-code/ParseHtmlMail.zip")
  runtime = "python3.9"
  timeout = "15"
  environment {
    variables = {
      ses_emails_recipients = local.ses_emails_list
      ses_emails_sender = var.ses_emails_sender
    }
  }
}

resource "aws_cloudwatch_log_group" "ParseHtmlMail" {
  name = "/aws/lambda/${var.project}-ParseHtmlMail"
}
