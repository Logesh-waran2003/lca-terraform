locals {
  common_tags = {
    Project     = "LCA"
    LOB         = var.lob
    ManagedBy   = "Terraform"
    Environment = "production"
  }

  roles = {
    call_event_processor = {
      role_name     = "call-event-processor-role-${var.lob}"
      trust_service = "lambda.amazonaws.com"
    }
    contact_event_processor = {
      role_name     = "contact-event-processor-role-${var.lob}"
      trust_service = "lambda.amazonaws.com"
    }
    fetch_transcript = {
      role_name     = "fetch-transcript-role-${var.lob}"
      trust_service = "lambda.amazonaws.com"
    }
    bedrock_summary = {
      role_name     = "bedrock-summary-role-${var.lob}"
      trust_service = "lambda.amazonaws.com"
    }
    llm_anthropic_summary = {
      role_name     = "llm-anthropic-summary-role-${var.lob}"
      trust_service = "lambda.amazonaws.com"
    }
    async_transcript_summary = {
      role_name     = "async-transcript-summary-role-${var.lob}"
      trust_service = "lambda.amazonaws.com"
    }
    async_agent_assist = {
      role_name     = "async-agent-assist-role-${var.lob}"
      trust_service = "lambda.amazonaws.com"
    }
    email_domain_verify = {
      role_name     = "email-domain-verify-role-${var.lob}"
      trust_service = "lambda.amazonaws.com"
    }
    associate_instance = {
      role_name     = "associate-instance-role-${var.lob}"
      trust_service = "lambda.amazonaws.com"
    }
    update_lca_settings = {
      role_name     = "update-lca-settings-role-${var.lob}"
      trust_service = "lambda.amazonaws.com"
    }
    llm_prompt_upload = {
      role_name     = "llm-prompt-upload-role-${var.lob}"
      trust_service = "lambda.amazonaws.com"
    }
    appsync_cwl = {
      role_name     = "appsync-cwl-role-${var.lob}"
      trust_service = "appsync.amazonaws.com"
    }
    appsync_dynamodb = {
      role_name     = "appsync-dynamodb-role-${var.lob}"
      trust_service = "appsync.amazonaws.com"
    }
  }
}

# ── IAM Roles (Lambda + AppSync) ──

resource "aws_iam_role" "roles" {
  for_each = local.roles

  name = each.value.role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = each.value.trust_service }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = local.common_tags
}

# ── Cognito Authorized Role (federated — authenticated) ──

resource "aws_iam_role" "cognito_authorized" {
  name = "cognito-authorized-role-${var.lob}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = "cognito-identity.amazonaws.com" }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "cognito-identity.amazonaws.com:aud" = "PLACEHOLDER_IDENTITY_POOL"
        }
        "ForAnyValue:StringLike" = {
          "cognito-identity.amazonaws.com:amr" = "authenticated"
        }
      }
    }]
  })

  tags = local.common_tags
}

# ── Agent Assist Unauthenticated Role (federated — unauthenticated) ──
# NOTE: No aud condition allowed for unauthenticated roles per AWS policy.
# Only amr = unauthenticated is required.

resource "aws_iam_role" "agent_assist_unauth" {
  name = "agent-assist-unauth-role-${var.lob}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = "cognito-identity.amazonaws.com" }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "cognito-identity.amazonaws.com:amr" = "unauthenticated"
        }
      }
    }]
  })

  tags = local.common_tags
}

# ── Managed Policy Attachments ──

resource "aws_iam_role_policy_attachment" "basic_execution" {
  for_each = {
    for k, v in local.roles : k => v
    if contains([
      "call_event_processor",
      "fetch_transcript",
      "bedrock_summary",
      "llm_anthropic_summary",
      "async_transcript_summary",
      "async_agent_assist",
      "email_domain_verify",
      "associate_instance",
      "update_lca_settings",
      "llm_prompt_upload"
    ], k)
  }

  role       = aws_iam_role.roles[each.key].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "call_event_processor_kinesis" {
  role       = aws_iam_role.roles["call_event_processor"].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaKinesisExecutionRole"
}

resource "aws_iam_role_policy_attachment" "contact_event_processor_insights" {
  role       = aws_iam_role.roles["contact_event_processor"].name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLambdaInsightsExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "contact_event_processor_xray" {
  role       = aws_iam_role.roles["contact_event_processor"].name
  policy_arn = "arn:aws:iam::aws:policy/AWSXrayWriteOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "appsync_cwl_logs" {
  role       = aws_iam_role.roles["appsync_cwl"].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSAppSyncPushToCloudWatchLogs"
}

# ── Inline Policies ──

# call_event_processor — DynamoDB access
resource "aws_iam_role_policy" "call_event_processor_dynamodb" {
  name = "DynamoDBAccess-${var.lob}"
  role = aws_iam_role.roles["call_event_processor"].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "dynamodb:GetItem",
        "dynamodb:DeleteItem",
        "dynamodb:PutItem",
        "dynamodb:Scan",
        "dynamodb:Query",
        "dynamodb:UpdateItem",
        "dynamodb:BatchWriteItem",
        "dynamodb:BatchGetItem",
        "dynamodb:DescribeTable",
        "dynamodb:ConditionCheckItem"
      ]
      Resource = [
        var.event_sourcing_table_arn,
        "${var.event_sourcing_table_arn}/index/*"
      ]
    }]
  })
}

# call_event_processor — SNS, SSM, AppSync, Comprehend, Events, Lambda
resource "aws_iam_role_policy" "call_event_processor_services" {
  name = "ServicesAccess-${var.lob}"
  role = aws_iam_role.roles["call_event_processor"].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["sns:Publish"]
        Resource = [var.sns_topic_arn]
      },
      {
        Effect   = "Allow"
        Action   = ["ssm:GetParameter"]
        Resource = ["arn:aws:ssm:${var.region}:${var.account_id}:parameter/*"]
      },
      {
        Effect   = "Allow"
        Action   = ["appsync:GraphQL"]
        Resource = ["arn:aws:appsync:${var.region}:${var.account_id}:apis/*/types/*/fields/*"]
      },
      {
        Effect   = "Allow"
        Action   = ["comprehend:DetectSentiment"]
        Resource = ["*"]
      },
      {
        Effect   = "Allow"
        Action   = ["events:PutEvents"]
        Resource = ["arn:aws:events:${var.region}:${var.account_id}:event-bus/default"]
      },
      {
        Effect   = "Allow"
        Action   = ["lambda:InvokeFunction"]
        Resource = ["arn:aws:lambda:${var.region}:${var.account_id}:function:async-*-${var.lob}"]
      }
    ]
  })
}

# contact_event_processor
resource "aws_iam_role_policy" "contact_event_processor_inline" {
  name = "ContactEventProcessorPolicy-${var.lob}"
  role = aws_iam_role.roles["contact_event_processor"].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = ["arn:aws:logs:${var.region}:${var.account_id}:*"]
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:Query",
          "dynamodb:Scan",
          "dynamodb:GetItem"
        ]
        Resource = [
          var.event_sourcing_table_arn,
          "${var.event_sourcing_table_arn}/index/*"
        ]
      },
      {
        Effect   = "Allow"
        Action   = ["connect:DescribeUser"]
        Resource = ["${var.connect_instance_arn}/user/*"]
      },
      {
        Effect   = "Allow"
        Action   = ["kinesis:PutRecord"]
        Resource = [var.call_data_stream_arn]
      }
    ]
  })
}

# fetch_transcript
resource "aws_iam_role_policy" "fetch_transcript_inline" {
  name = "FetchTranscriptPolicy-${var.lob}"
  role = aws_iam_role.roles["fetch_transcript"].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = ["dynamodb:Query"]
      Resource = [
        var.event_sourcing_table_arn,
        "${var.event_sourcing_table_arn}/index/*"
      ]
    }]
  })
}

# bedrock_summary
resource "aws_iam_role_policy" "bedrock_summary_inline" {
  name = "BedrockSummaryPolicy-${var.lob}"
  role = aws_iam_role.roles["bedrock_summary"].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["lambda:InvokeFunction"]
        Resource = ["arn:aws:lambda:${var.region}:${var.account_id}:function:fetch-transcript-${var.lob}"]
      },
      {
        Effect   = "Allow"
        Action   = ["dynamodb:GetItem"]
        Resource = [var.llm_prompt_table_arn]
      },
      {
        Effect = "Allow"
        Action = ["bedrock:InvokeModel"]
        Resource = [
          "arn:aws:bedrock:*::foundation-model/*",
          "arn:aws:bedrock:${var.region}:${var.account_id}:inference-profile/*"
        ]
      },
      {
        Effect   = "Allow"
        Action   = ["bedrock:GetInferenceProfile"]
        Resource = ["arn:aws:bedrock:${var.region}:${var.account_id}:inference-profile/*"]
      }
    ]
  })
}

# llm_anthropic_summary
resource "aws_iam_role_policy" "llm_anthropic_summary_inline" {
  name = "LLMAnthropicSummaryPolicy-${var.lob}"
  role = aws_iam_role.roles["llm_anthropic_summary"].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["lambda:InvokeFunction"]
      Resource = ["arn:aws:lambda:${var.region}:${var.account_id}:function:fetch-transcript-${var.lob}"]
    }]
  })
}

# async_transcript_summary
resource "aws_iam_role_policy" "async_transcript_summary_inline" {
  name = "AsyncTranscriptSummaryPolicy-${var.lob}"
  role = aws_iam_role.roles["async_transcript_summary"].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["kinesis:PutRecord"]
        Resource = [var.call_data_stream_arn]
      },
      {
        Effect   = "Allow"
        Action   = ["lambda:InvokeFunction"]
        Resource = ["arn:aws:lambda:${var.region}:${var.account_id}:function:bedrock-summary-${var.lob}"]
      }
    ]
  })
}

# async_agent_assist
resource "aws_iam_role_policy" "async_agent_assist_inline" {
  name = "AsyncAgentAssistPolicy-${var.lob}"
  role = aws_iam_role.roles["async_agent_assist"].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["kinesis:PutRecord"]
        Resource = [var.call_data_stream_arn]
      },
      {
        Effect   = "Allow"
        Action   = ["lex:RecognizeText"]
        Resource = ["*"]
      }
    ]
  })
}

# associate_instance
resource "aws_iam_role_policy" "associate_instance_inline" {
  name = "AssociateInstancePolicy-${var.lob}"
  role = aws_iam_role.roles["associate_instance"].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "connect:AssociateInstanceStorageConfig",
          "connect:ListInstanceStorageConfigs",
          "connect:DisassociateInstanceStorageConfig"
        ]
        Resource = [var.connect_instance_arn]
      },
      {
        Effect   = "Allow"
        Action   = ["kinesis:DescribeStream"]
        Resource = [var.call_data_stream_arn]
      },
      {
        Effect   = "Allow"
        Action   = ["iam:PutRolePolicy"]
        Resource = ["arn:aws:iam::${var.account_id}:role/aws-service-role/connect.amazonaws.com/AWSServiceRoleForAmazonConnect_*"]
      }
    ]
  })
}

# update_lca_settings
resource "aws_iam_role_policy" "update_lca_settings_inline" {
  name = "UpdateLCASettingsPolicy-${var.lob}"
  role = aws_iam_role.roles["update_lca_settings"].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "ssm:GetParameter",
        "ssm:PutParameter"
      ]
      Resource = [var.lca_settings_parameter_arn]
    }]
  })
}

# llm_prompt_upload
resource "aws_iam_role_policy" "llm_prompt_upload_inline" {
  name = "LLMPromptUploadPolicy-${var.lob}"
  role = aws_iam_role.roles["llm_prompt_upload"].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:UpdateItem"
        ]
        Resource = [var.llm_prompt_table_arn]
      },
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters"
        ]
        Resource = ["*"]
      }
    ]
  })
}

# cognito_authorized
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

# agent_assist_unauth
resource "aws_iam_role_policy" "agent_assist_unauth_inline" {
  name = "AgentAssistUnauthPolicy-${var.lob}"
  role = aws_iam_role.agent_assist_unauth.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["lex:RecognizeText"]
      Resource = ["arn:aws:lex:${var.region}:${var.account_id}:bot-alias/PLCHLDR/PLCHLDR"]
    }]
  })
}

# appsync_dynamodb
resource "aws_iam_role_policy" "appsync_dynamodb_inline" {
  name = "AppSyncDynamoDBPolicy-${var.lob}"
  role = aws_iam_role.roles["appsync_dynamodb"].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "dynamodb:Query",
        "dynamodb:Scan",
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:UpdateItem"
      ]
      Resource = [
        var.event_sourcing_table_arn,
        "${var.event_sourcing_table_arn}/index/*"
      ]
    }]
  })
}


