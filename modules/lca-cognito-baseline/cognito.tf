resource "aws_lambda_function" "email_domain_verify" {
  function_name = "email-domain-verify-${var.lob}"
  role          = var.email_domain_verify_role_arn
  handler       = "index.handler"
  runtime       = "nodejs18.x"
  filename      = "${path.module}/../../lambda-files/email-domain-verify.zip"
  source_code_hash = filebase64sha256("${path.module}/../../lambda-files/email-domain-verify.zip")
  timeout       = 3
  memory_size   = 128
  architectures = ["x86_64"]

  environment {
    variables = {
      ALLOWED_SIGNUP_EMAIL_DOMAINS = var.allowed_email_domain
    }
  }

  tags = {
    Project     = "LCA"
    LOB         = var.lob
    ManagedBy   = "Terraform"
    Environment = "production"
  }
}

resource "aws_cognito_user_pool" "main" {
  name = "user-pool-${var.lob}"

  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]

  username_configuration {
    case_sensitive = false
  }

  schema {
    name                = "email"
    attribute_data_type = "String"
    required            = true
    mutable             = false

    string_attribute_constraints {
      min_length = 0
      max_length = 2048
    }
  }

  schema {
    name                = "email_alias"
    attribute_data_type = "String"
    required            = false
    mutable             = true

    string_attribute_constraints {
      min_length = 0
      max_length = 256
    }
  }

  lambda_config {
    pre_sign_up        = aws_lambda_function.email_domain_verify.arn
    pre_authentication = aws_lambda_function.email_domain_verify.arn
  }

  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_symbols   = true
    require_uppercase = true
  }

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  admin_create_user_config {
    allow_admin_create_user_only = false
  }

  email_configuration {
    email_sending_account = "COGNITO_DEFAULT"
  }

  tags = {
    Project     = "LCA"
    LOB         = var.lob
    ManagedBy   = "Terraform"
    Environment = "production"
  }
}

resource "aws_lambda_permission" "cognito_invoke_email_verify" {
  statement_id  = "AllowCognitoInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.email_domain_verify.function_name
  principal     = "cognito-idp.amazonaws.com"
  source_arn    = aws_cognito_user_pool.main.arn
}

resource "aws_cognito_user_pool_domain" "main" {
  domain       = "tih-${var.lob}-lca"
  user_pool_id = aws_cognito_user_pool.main.id
}

resource "aws_cognito_user_pool_client" "main" {
  name         = "user-pool-client-${var.lob}"
  user_pool_id = aws_cognito_user_pool.main.id

  explicit_auth_flows = [
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH"
  ]

  supported_identity_providers = ["COGNITO"]

  access_token_validity  = 1
  id_token_validity      = 1
  refresh_token_validity = 30

  token_validity_units {
    access_token  = "hours"
    id_token      = "hours"
    refresh_token = "days"
  }

  prevent_user_existence_errors = "ENABLED"
  enable_token_revocation       = true

  read_attributes  = ["email", "email_verified", "preferred_username"]
  generate_secret  = false
}

resource "aws_cognito_user_group" "admin" {
  name         = "Admin"
  description  = "Administrators"
  precedence   = 0
  user_pool_id = aws_cognito_user_pool.main.id
}

resource "null_resource" "admin_user" {
  triggers = {
    user_pool_id = aws_cognito_user_pool.main.id
    admin_email  = var.admin_email
  }

  provisioner "local-exec" {
    command = "aws cognito-idp admin-create-user --user-pool-id ${aws_cognito_user_pool.main.id} --username ${var.admin_email} --user-attributes Name=email,Value=${var.admin_email} Name=email_verified,Value=true --desired-delivery-mediums EMAIL --region ${var.region} || echo \"User may already exist, continuing\""
  }

  depends_on = [aws_lambda_permission.cognito_invoke_email_verify]
}

resource "null_resource" "admin_user_group" {
  triggers = {
    user_pool_id = aws_cognito_user_pool.main.id
    admin_email  = var.admin_email
  }

  provisioner "local-exec" {
    command = "aws cognito-idp admin-add-user-to-group --user-pool-id ${aws_cognito_user_pool.main.id} --username ${var.admin_email} --group-name Admin --region ${var.region}"
  }

  depends_on = [
    aws_cognito_user_group.admin,
    null_resource.admin_user
  ]
}

resource "aws_cognito_identity_pool" "main" {
  identity_pool_name               = "identity-pool-${var.lob}"
  allow_unauthenticated_identities = false

  cognito_identity_providers {
    client_id               = aws_cognito_user_pool_client.main.id
    provider_name           = aws_cognito_user_pool.main.endpoint
    server_side_token_check = false
  }

  tags = {
    Project     = "LCA"
    LOB         = var.lob
    ManagedBy   = "Terraform"
    Environment = "production"
  }
}

resource "aws_cognito_identity_pool_roles_attachment" "main" {
  identity_pool_id = aws_cognito_identity_pool.main.id

  roles = {
    authenticated = var.cognito_authorized_role_arn
  }
}

resource "aws_cognito_identity_pool" "agent_assist" {
  identity_pool_name               = "agent-assist-identity-pool-${var.lob}"
  allow_unauthenticated_identities = true

  tags = {
    Project     = "LCA"
    LOB         = var.lob
    ManagedBy   = "Terraform"
    Environment = "production"
  }
}

resource "aws_cognito_identity_pool_roles_attachment" "agent_assist" {
  identity_pool_id = aws_cognito_identity_pool.agent_assist.id

  roles = {
    unauthenticated = var.agent_assist_unauth_role_arn
  }
}
