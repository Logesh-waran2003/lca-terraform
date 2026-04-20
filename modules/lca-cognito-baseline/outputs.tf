output "user_pool_id" {
  value = aws_cognito_user_pool.main.id
}

output "user_pool_arn" {
  value = aws_cognito_user_pool.main.arn
}

output "user_pool_client_id" {
  value = aws_cognito_user_pool_client.main.id
}

output "identity_pool_id" {
  value = aws_cognito_identity_pool.main.id
}

output "agent_assist_identity_pool_id" {
  value = aws_cognito_identity_pool.agent_assist.id
}

output "email_domain_verify_function_arn" {
  value = aws_lambda_function.email_domain_verify.arn
}

output "saml_entity_id" {
  value = "urn:amazon:cognito:sp:${aws_cognito_user_pool.main.id}"
}

output "saml_acs_url" {
  value = "https://tih-${var.lob}-lca.auth.${var.region}.amazoncognito.com/saml2/idpresponse"
}

output "cognito_domain" {
  value = "tih-${var.lob}-lca.auth.${var.region}.amazoncognito.com"
}
