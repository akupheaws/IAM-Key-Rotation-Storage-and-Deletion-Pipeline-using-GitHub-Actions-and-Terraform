resource "aws_secretsmanager_secret" "key_secret" {
  name        = var.secret_name
  description = "Holds latest IAM access key for ${var.target_username} under '${var.secret_json_key}'."
}

resource "aws_secretsmanager_secret_version" "initial" {
  secret_id     = aws_secretsmanager_secret.key_secret.id
  secret_string = jsonencode({ (var.secret_json_key) = { note = "placeholder - overwritten by Lambda" } })
}
