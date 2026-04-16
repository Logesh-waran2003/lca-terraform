output "settings_parameter_name" {
  value = aws_ssm_parameter.lca_settings.name
}

output "settings_parameter_arn" {
  value = aws_ssm_parameter.lca_settings.arn
}
