variable "region" {
  type        = string
  description = "region where the resources will be created"
}
variable "account_id" {
  type        = string
  description = "aws security account id where security hub is centralized, aggregating all the accounts findings"
}

variable "accounts_list" {
  type    = list(string)
  description = "list of aws accounts ids managed by security hub centralized account"
}

variable "project" {
  type        = string
  description = "project code to be used for resources naming"
}

variable "dynamodb_table" {
  type        = string
  description = "dynamodb table that will be created"
}

variable "ses_emails_sender" {
  type = string
  description = "email address to send finding emails"
}
variable "ses_emails_recipients" {
  type = map
  description = "list of emails addreses to receive finding emails"
}

variable "findings_severity" {
  type    = list(string)
  description = "list of severity findings to filter in eventrule"
}