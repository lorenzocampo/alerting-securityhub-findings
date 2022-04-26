resource "aws_cloudwatch_event_rule" "Findings-EventRule" {
  name        = "${var.project}-Findings-EventRule"
  description = "Capture Security Hub Findings"
  is_enabled     = false
  event_pattern = <<EOF
{
  "source": ["aws.securityhub"],
  "detail-type": ["Security Hub Findings - Imported"],
  "detail": {
    "findings": {
      "AwsAccountId": ${local.accounts_list},
      "RecordState": ["ACTIVE"],
      "Workflow": {
        "Status": ["NEW"]
      },
      "Severity": {
        "Label": ${local.findings_severity}
      },
      "ProductName": ["Security Hub", "GuardDuty", "Inspector"]
    }
  }
}
EOF
}

resource "aws_cloudwatch_event_target" "step_functions" {
  rule      = aws_cloudwatch_event_rule.Findings-EventRule.name
  target_id = "SendTo${var.project}StepFunctions"
  arn       = aws_sfn_state_machine.sfn_state_machine.arn
  role_arn = aws_iam_role.EventRule-StepFunctions-Role.arn
}

resource "aws_iam_role" "EventRule-StepFunctions-Role" {
  name               = "${var.project}-EventRule-StepFunctions-Role"
  assume_role_policy = data.aws_iam_policy_document.eventrule-stepfunctions-assume-role-policy.json
  inline_policy {
    name = "StepFunctionsPolicy"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
            Effect: "Allow",
            Action: [ "states:StartExecution" ],
            Resource: "arn:aws:states:${var.region}:${var.account_id}:stateMachine:${var.project}StateMachine"
        }
      ]
    })
  }
}

