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

  schema {
    name                = "email"
    attribute_data_type = "String"
    required            = true
    mutable             = true

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

    invite_message_template {
      email_subject = "Welcome to Live Call Analytics with Agent Assist!"
      email_message = <<-EOF
<p>Hello {username},</p>
<p>Welcome to Live Call Analytics with Agent Assist (LCA)! Your temporary password is: <strong>{####}</strong></p>
<p>Use the link below to log in and set your permanent password.</p>
<p>     https://${var.cloudfront_domain}/</p>
<p>Thanks,</p>
<p>Live Call Analytics with Agent Assist</p>
EOF
      sms_message   = "Your username is {username} and temporary password is {####}."
    }
  }

  email_configuration {
    email_sending_account = "COGNITO_DEFAULT"
  }

  email_verification_message = "Please verify your email to complete account registration. Confirmation Code {####}."
  email_verification_subject = "Account Verification"

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

resource "aws_cognito_identity_provider" "entraid" {
  user_pool_id  = aws_cognito_user_pool.main.id
  provider_name = "EntraID"
  provider_type = "SAML"

  provider_details = {
    MetadataURL = var.saml_metadata_url
    IDPInit     = "true"
    IDPSignout  = "false"
  }

  attribute_mapping = {
    email                = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress"
    "custom:email_alias" = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress"
    username             = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress"
  }
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

  supported_identity_providers = ["EntraID"]

  allowed_oauth_flows                  = ["code", "implicit"]
  allowed_oauth_scopes                 = ["openid", "email", "phone"]
  allowed_oauth_flows_user_pool_client = true

  callback_urls        = ["https://${var.cloudfront_domain}", "https://${var.cloudfront_domain}/"]
  logout_urls          = ["https://${var.cloudfront_domain}", "https://${var.cloudfront_domain}/"]
  default_redirect_uri = "https://${var.cloudfront_domain}"

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

  read_attributes  = ["email", "email_verified", "phone_number", "phone_number_verified", "preferred_username", "custom:email_alias"]
  write_attributes = ["email", "custom:email_alias"]
  generate_secret  = false

  depends_on = [aws_cognito_identity_provider.entraid]
}

resource "aws_cognito_user_group" "admin" {
  name         = "Admin"
  description  = "Administrators"
  precedence   = 0
  user_pool_id = aws_cognito_user_pool.main.id
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
    authenticated = aws_iam_role.cognito_authorized.arn
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
    unauthenticated = aws_iam_role.agent_assist_unauth.arn
  }
}

# ── Cognito-federated IAM Roles ──
# These live here (not in IAM module) because they need identity pool IDs
# in their trust policies, which creates a circular dependency if in IAM.

resource "aws_iam_role" "cognito_authorized" {
  name = "cognito-authorized-role-${var.lob}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = "cognito-identity.amazonaws.com" }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        "StringEquals" = {
          "cognito-identity.amazonaws.com:aud" = aws_cognito_identity_pool.main.id
        }
        "ForAnyValue:StringLike" = {
          "cognito-identity.amazonaws.com:amr" = "authenticated"
        }
      }
    }]
  })

  tags = {
    Project     = "LCA"
    LOB         = var.lob
    ManagedBy   = "Terraform"
    Environment = "production"
  }
}

resource "aws_iam_role" "agent_assist_unauth" {
  name = "agent-assist-unauth-role-${var.lob}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = "cognito-identity.amazonaws.com" }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        "StringEquals" = {
          "cognito-identity.amazonaws.com:aud" = aws_cognito_identity_pool.agent_assist.id
        }
        "ForAnyValue:StringLike" = {
          "cognito-identity.amazonaws.com:amr" = "unauthenticated"
        }
      }
    }]
  })

  tags = {
    Project     = "LCA"
    LOB         = var.lob
    ManagedBy   = "Terraform"
    Environment = "production"
  }
}

resource "aws_iam_role_policy" "cognito_authorized_inline" {
  name = "CognitoAuthorizedPolicy-${var.lob}"
  role = aws_iam_role.cognito_authorized.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["s3:GetObject"]
        Resource = [
          var.recordings_bucket_arn,
          "${var.recordings_bucket_arn}/*"
        ]
      },
      {
        Effect   = "Allow"
        Action   = ["ssm:GetParameter"]
        Resource = [var.lca_settings_parameter_arn]
      },
      {
        Effect   = "Allow"
        Action   = ["translate:TranslateText"]
        Resource = ["*"]
      },
      {
        Effect   = "Allow"
        Action   = ["comprehend:DetectDominantLanguage"]
        Resource = ["*"]
      }
    ]
  })
}

resource "aws_iam_role_policy" "agent_assist_unauth_inline" {
  name = "AgentAssistUnauthPolicy-${var.lob}"
  role = aws_iam_role.agent_assist_unauth.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["lex:RecognizeText"]
      Resource = ["*"]
    }]
  })
}

# ── Admin User ──

resource "aws_cognito_user" "admin" {
  user_pool_id = aws_cognito_user_pool.main.id
  username     = var.admin_email

  attributes = {
    email          = var.admin_email
    email_verified = "true"
  }

  desired_delivery_mediums = ["EMAIL"]
}

resource "aws_cognito_user_in_group" "admin" {
  user_pool_id = aws_cognito_user_pool.main.id
  group_name   = aws_cognito_user_group.admin.name
  username     = aws_cognito_user.admin.username
}
