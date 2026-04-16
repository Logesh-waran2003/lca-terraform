resource "aws_ssm_parameter" "lca_settings" {
  name  = "lca-settings-${var.lob}"
  type  = "String"
  value = "{}"

  tags = {
    Project     = "LCA"
    LOB         = var.lob
    ManagedBy   = "Terraform"
    Environment = "production"
  }
}

resource "aws_lambda_function" "update_lca_settings" {
  function_name = "update-lca-settings-${var.lob}"
  role          = var.update_settings_role_arn
  handler       = "index.handler"
  runtime       = "python3.12"
  filename      = "${path.module}/../../lambda-files/update-lca-settings.zip"
  source_code_hash = filebase64sha256("${path.module}/../../lambda-files/update-lca-settings.zip")
  timeout       = 900
  architectures = ["x86_64"]

  tags = {
    Project     = "LCA"
    LOB         = var.lob
    ManagedBy   = "Terraform"
    Environment = "production"
  }
}

resource "null_resource" "update_lca_settings_initial" {
  triggers = {
    parameter_name = aws_ssm_parameter.lca_settings.name
  }

  provisioner "local-exec" {
    command = "aws lambda invoke --function-name ${aws_lambda_function.update_lca_settings.function_name} --payload \"{\\\"LCASettingsName\\\":\\\"${aws_ssm_parameter.lca_settings.name}\\\",\\\"LCASettingsKeyValuePairs\\\":{\\\"CategoryAlertRegex\\\":\\\"${var.category_alert_regex}\\\"}}\" --cli-binary-format raw-in-base64-out --region ${var.region} update-settings-response.json"
  }

  depends_on = [
    aws_lambda_function.update_lca_settings,
    aws_ssm_parameter.lca_settings
  ]
}

resource "aws_lambda_function" "llm_prompt_upload" {
  function_name = "llm-prompt-upload-${var.lob}"
  role          = var.llm_prompt_upload_role_arn
  handler       = "llm_prompt_upload.lambda_handler"
  runtime       = "python3.12"
  filename      = "${path.module}/../../lambda-files/llm-prompt-upload.zip"
  source_code_hash = filebase64sha256("${path.module}/../../lambda-files/llm-prompt-upload.zip")
  timeout       = 60
  architectures = ["x86_64"]

  tags = {
    Project     = "LCA"
    LOB         = var.lob
    ManagedBy   = "Terraform"
    Environment = "production"
  }
}

resource "null_resource" "seed_llm_prompts" {
  triggers = {
    table_name = var.llm_prompt_table_name
  }

  provisioner "local-exec" {
    command = "aws lambda invoke --function-name ${aws_lambda_function.llm_prompt_upload.function_name} --payload \"{\\\"LLMPromptTemplateTableName\\\":\\\"${var.llm_prompt_table_name}\\\"}\" --cli-binary-format raw-in-base64-out --region ${var.region} seed-prompts-response.json"
  }

  depends_on = [aws_lambda_function.llm_prompt_upload]
}
