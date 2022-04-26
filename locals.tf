locals {
  accounts_list = jsonencode(var.accounts_list)
  findings_severity = jsonencode(var.findings_severity)
  ses_emails_list = jsonencode(var.ses_emails_recipients)
}