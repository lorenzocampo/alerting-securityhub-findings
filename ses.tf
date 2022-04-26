resource "aws_ses_email_identity" "ses_email_sender" {
  email = var.ses_emails_sender
}

resource "aws_ses_email_identity" "ses_email_recipients" {
  for_each = var.ses_emails_recipients
  email = each.value
}