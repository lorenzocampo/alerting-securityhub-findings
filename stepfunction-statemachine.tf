resource "aws_iam_role" "SHStateMachine-Role" {
  name               = "${var.project}-StateMachine-Role"
  assume_role_policy = data.aws_iam_policy_document.securityhub-assume-role-policy.json
  inline_policy {
    name = "CloudWatchLogsDeliveryFullAccessPolicy"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
            Effect: "Allow",
            Action: [
                "logs:CreateLogDelivery",
                "logs:GetLogDelivery",
                "logs:UpdateLogDelivery",
                "logs:DeleteLogDelivery",
                "logs:ListLogDeliveries",
                "logs:PutResourcePolicy",
                "logs:DescribeResourcePolicies",
                "logs:DescribeLogGroups"
            ],
            Resource: "*"
        }
      ]
    })
  }
  inline_policy {
    name = "LambdaInvokeScopedAccessPolicy"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
            Effect: "Allow",
            Action: [
                "lambda:InvokeFunction"
            ],
            Resource: [
                "arn:aws:lambda:${var.region}:${var.account_id}:function:${var.project}-DynamoDB:*",
                "arn:aws:lambda:${var.region}:${var.account_id}:function:${var.project}-CheckOldFindingsState:*",
                "arn:aws:lambda:${var.region}:${var.account_id}:function:${var.project}-ParseHtmlMail:*"
            ]
        }
      ]
    })
  }
  inline_policy {
    name = "XRayAccessPolicy"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
            Effect: "Allow",
            Action: [
                "xray:PutTraceSegments",
                "xray:PutTelemetryRecords",
                "xray:GetSamplingRules",
                "xray:GetSamplingTargets"
            ],
            Resource: [
                "*"
            ]
        }
      ]
    })
  }
}

resource "aws_cloudwatch_log_group" "StateMachine" {
  name = "/aws/step_functions/${var.project}-StateMachine"
}

resource "aws_sfn_state_machine" "sfn_state_machine" {
  name     = "${var.project}StateMachine"
  role_arn = aws_iam_role.SHStateMachine-Role.arn
  definition = <<EOF
{
  "Comment": "Security Hub Findings State Machine",
  "StartAt": "DynamoDB",
  "States": {
    "DynamoDB": {
      "Type": "Task",
      "Resource": "arn:aws:states:::lambda:invoke",
      "OutputPath": "$.Payload",
      "Parameters": {
        "Payload.$": "$",
        "FunctionName": "arn:aws:lambda:${var.region}:${var.account_id}:function:${var.project}-DynamoDB:$LATEST"
      },
      "Retry": [
        {
          "ErrorEquals": [
            "Lambda.ServiceException",
            "Lambda.AWSLambdaException",
            "Lambda.SdkClientException"
          ],
          "IntervalSeconds": 2,
          "MaxAttempts": 6,
          "BackoffRate": 2
        }
      ],
      "Next": "New Finding?"
    },
    "New Finding?": {
      "Type": "Choice",
      "Choices": [
        {
          "Variable": "$.Message",
          "StringMatches": "Item added to DynamoDB Table",
          "Next": "Parse mail in HTML"
        }
      ],
      "Default": "CheckOldFindingsState"
    },
    "Parse mail in HTML": {
      "Type": "Task",
      "Resource": "arn:aws:states:::lambda:invoke",
      "OutputPath": "$.Payload",
      "Parameters": {
        "Payload.$": "$",
        "FunctionName": "arn:aws:lambda:${var.region}:${var.account_id}:function:${var.project}-ParseHtmlMail:$LATEST"
      },
      "Retry": [
        {
          "ErrorEquals": [
            "Lambda.ServiceException",
            "Lambda.AWSLambdaException",
            "Lambda.SdkClientException"
          ],
          "IntervalSeconds": 2,
          "MaxAttempts": 6,
          "BackoffRate": 2
        }
      ],
      "End": true
    },
    "CheckOldFindingsState": {
      "Type": "Task",
      "Resource": "arn:aws:states:::lambda:invoke",
      "OutputPath": "$.Payload",
      "Parameters": {
        "Payload.$": "$",
        "FunctionName": "arn:aws:lambda:${var.region}:${var.account_id}:function:${var.project}-CheckOldFindingsState:$LATEST"
      },
      "Retry": [
        {
          "ErrorEquals": [
            "Lambda.ServiceException",
            "Lambda.AWSLambdaException",
            "Lambda.SdkClientException"
          ],
          "IntervalSeconds": 2,
          "MaxAttempts": 6,
          "BackoffRate": 2
        }
      ],
      "Next": "More than 15 days unresolved?"
    },
    "More than 15 days unresolved?": {
      "Type": "Choice",
      "Choices": [
        {
          "Variable": "$.SendToOperations",
          "StringEquals": "True",
          "Next": "Parse mail in HTML"
        }
      ],
      "Default": "Do nothing"
    },
    "Do nothing": {
      "Type": "Succeed"
    }
  }
}
EOF
  logging_configuration {
    log_destination        = "${aws_cloudwatch_log_group.StateMachine.arn}:*"
    include_execution_data = true
    level                  = "ALL"
  }
}