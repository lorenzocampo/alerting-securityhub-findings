resource "aws_dynamodb_table" "dynamodb_table" {
  name           = "${var.dynamodb_table}"
  hash_key       = "Resource"
  range_key      = "Title"
  billing_mode   = "PROVISIONED"
  read_capacity  = 30
  write_capacity = 30
  point_in_time_recovery {
        enabled = true
  }

  attribute {
    name = "Resource"
    type = "S"
  }

  attribute {
    name = "Title"
    type = "S"
  }
}
