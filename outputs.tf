# ── For React .env file ──
output "user_pool_id" {
  value = module.lca_cognito.user_pool_id
}

output "user_pool_client_id" {
  value = module.lca_cognito.user_pool_client_id
}

output "identity_pool_id" {
  value = module.lca_cognito.identity_pool_id
}

output "appsync_graphql_url" {
  value = module.lca_appsync.graphql_url
}

output "cloudfront_url" {
  value = module.lca_frontend.cloudfront_url
}

output "cloudfront_distribution_id" {
  value = module.lca_frontend.cloudfront_distribution_id
}

output "webapp_bucket_name" {
  value = module.lca_storage.webapp_bucket_name
}

output "recordings_bucket_name" {
  value = module.lca_storage.recordings_bucket_name
}

output "cognito_domain" {
  value = module.lca_cognito.cognito_domain
}

output "aws_region" {
  value = var.aws_region
}

# ── For SSO configuration (post-apply manual steps) ──
output "saml_entity_id" {
  value = module.lca_cognito.saml_entity_id
}

output "saml_acs_url" {
  value = module.lca_cognito.saml_acs_url
}

# ── React .env file content (copy paste ready) ──
output "react_env_file" {
  value = <<-EOF

    ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    Copy this into your React .env file before building:
    ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    REACT_APP_AWS_REGION=${var.aws_region}
    REACT_APP_USER_POOL_ID=${module.lca_cognito.user_pool_id}
    REACT_APP_USER_POOL_CLIENT_ID=${module.lca_cognito.user_pool_client_id}
    REACT_APP_IDENTITY_POOL_ID=${module.lca_cognito.identity_pool_id}
    REACT_APP_APPSYNC_GRAPHQL_URL=${module.lca_appsync.graphql_url}
    REACT_APP_CLOUDFRONT_DOMAIN=${module.lca_frontend.cloudfront_url}
    REACT_APP_SETTINGS_PARAMETER=${module.lca_ssm.settings_parameter_name}
    REACT_APP_ENABLE_LEX_AGENT_ASSIST=${tostring(var.is_lex_agent_assist_enabled)}
    REACT_APP_COGNITO_DOMAIN=${module.lca_cognito.cognito_domain}
    REACT_APP_APP_URL=${module.lca_frontend.cloudfront_url}
    DISABLE_ESLINT_PLUGIN=true

    ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    Post-apply manual steps:
    ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    1. Azure Enterprise App:
       Entity ID: ${module.lca_cognito.saml_entity_id}
       ACS URL:   ${module.lca_cognito.saml_acs_url}

    2. After Azure app created, add EntraID SAML provider in Cognito console
       and add "EntraID" to the app client's supported identity providers.

    3. React build:
       Fill .env with values above
       npm run build
       aws s3 sync build/ s3://${module.lca_storage.webapp_bucket_name} --delete
       aws cloudfront create-invalidation \
         --distribution-id ${module.lca_frontend.cloudfront_distribution_id} \
         --paths "/*"
  EOF
}
