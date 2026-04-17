# ── Resource Moves (IAM → Cognito module refactor) ──
# These tell Terraform the resources were moved, not deleted+recreated.
# Safe to remove after first successful apply.

moved {
  from = module.lca_iam.aws_iam_role.cognito_authorized
  to   = module.lca_cognito.aws_iam_role.cognito_authorized
}

moved {
  from = module.lca_iam.aws_iam_role.agent_assist_unauth
  to   = module.lca_cognito.aws_iam_role.agent_assist_unauth
}

moved {
  from = module.lca_iam.aws_iam_role_policy.cognito_authorized_inline
  to   = module.lca_cognito.aws_iam_role_policy.cognito_authorized_inline
}

moved {
  from = module.lca_iam.aws_iam_role_policy.agent_assist_unauth_inline
  to   = module.lca_cognito.aws_iam_role_policy.agent_assist_unauth_inline
}

locals {
  lob = var.lob.name

  # Construct deterministic ARNs for resources that haven't been created yet
  # This breaks the circular dependency between IAM and SSM modules
  lca_settings_parameter_arn = "arn:aws:ssm:${var.aws_region}:${var.account_id}:parameter/lca-settings-${local.lob}"

  # Deterministic Lambda ARNs to break circular dependency
  # (locals references module.lca_lambda which consumes locals)
  lambda_arn_prefix              = "arn:aws:lambda:${var.aws_region}:${var.account_id}:function"
  fetch_transcript_arn           = "${local.lambda_arn_prefix}:fetch-transcript-${local.lob}"
  bedrock_summary_arn            = "${local.lambda_arn_prefix}:bedrock-summary-${local.lob}"
  async_transcript_summary_arn   = "${local.lambda_arn_prefix}:async-transcript-summary-${local.lob}"
  async_agent_assist_arn         = "${local.lambda_arn_prefix}:async-agent-assist-${local.lob}"

  # ── Resolve Lambda functions with all cross-module dependencies ──
  resolved_lca_lambdas = {

    call_event_processor = {
      function_name = "call-event-processor-${local.lob}"
      role_key      = "call_event_processor"
      runtime       = "python3.12"
      architectures = ["arm64"]
      memory_size   = 3000
      timeout       = 900
      filename      = "call-event-processor.zip"
      handler       = "lambda_function.handler"
      use_layer     = true
      environment = {
        LOG_LEVEL                                 = "DEBUG"
        POWERTOOLS_SERVICE_NAME                   = "TranscriptProcessor"
        POWERTOOLS_METRICS_NAMESPACE              = "TranscriptProcessor"
        POWERTOOLS_TRACE_DISABLED                 = "false"
        CALL_AUDIO_SOURCE                         = "Amazon Connect Contact Lens"
        COMPREHEND_LANGUAGE_CODE                  = var.comprehend_language_code
        IS_SENTIMENT_ANALYSIS_ENABLED             = tostring(var.is_sentiment_analysis_enabled)
        SENTIMENT_NEGATIVE_THRESHOLD              = tostring(var.sentiment_negative_threshold)
        SENTIMENT_POSITIVE_THRESHOLD              = tostring(var.sentiment_positive_threshold)
        IS_LEX_AGENT_ASSIST_ENABLED               = tostring(var.is_lex_agent_assist_enabled)
        IS_LAMBDA_AGENT_ASSIST_ENABLED            = tostring(var.is_lambda_agent_assist_enabled)
        DYNAMODB_EXPIRATION_IN_DAYS               = tostring(var.dynamodb_expiration_in_days)
        IS_TRANSCRIPT_SUMMARY_ENABLED             = "true"
        APPSYNC_GRAPHQL_URL                       = module.lca_appsync.graphql_url
        STATE_DYNAMODB_TABLE_NAME                 = module.lca_dynamodb.event_sourcing_table_name
        CALL_DATA_STREAM_NAME                     = module.lca_kinesis.stream_name
        SNS_TOPIC_ARN                             = module.lca_notifications.sns_topic_arn
        PARAMETER_STORE_NAME                      = module.lca_ssm.settings_parameter_name
        ASYNC_TRANSCRIPT_SUMMARY_ORCHESTRATOR_ARN = local.async_transcript_summary_arn
        ASYNC_AGENT_ASSIST_ORCHESTRATOR_ARN       = local.async_agent_assist_arn
      }
    }

    fetch_transcript = {
      function_name = "fetch-transcript-${local.lob}"
      role_key      = "fetch_transcript"
      runtime       = "python3.12"
      architectures = ["x86_64"]
      memory_size   = 128
      timeout       = 60
      filename      = "fetch-transcript.zip"
      handler       = "index.lambda_handler"
      use_layer     = false
      environment = {
        LCA_CALL_EVENTS_TABLE = module.lca_dynamodb.event_sourcing_table_name
      }
    }

    bedrock_summary = {
      function_name = "bedrock-summary-${local.lob}"
      role_key      = "bedrock_summary"
      runtime       = "python3.12"
      architectures = ["x86_64"]
      memory_size   = 512
      timeout       = 900
      filename      = "bedrock-summary.zip"
      handler       = "index.handler"
      use_layer     = false
      environment = {
        BEDROCK_MODEL_ID               = var.bedrock_model_id
        FETCH_TRANSCRIPT_LAMBDA_ARN    = local.fetch_transcript_arn
        LLM_PROMPT_TEMPLATE_TABLE_NAME = module.lca_dynamodb.llm_prompt_table_name
        TOKEN_COUNT                    = "0"
        PROCESS_TRANSCRIPT             = "True"
      }
    }

    llm_anthropic_summary = {
      function_name = "llm-anthropic-summary-${local.lob}"
      role_key      = "llm_anthropic_summary"
      runtime       = "python3.12"
      architectures = ["x86_64"]
      memory_size   = 128
      timeout       = 900
      filename      = "llm-anthropic-summary.zip"
      handler       = "index.handler"
      use_layer     = false
      environment = {
        LCA_CALL_EVENTS_TABLE        = module.lca_dynamodb.event_sourcing_table_name
        FETCH_TRANSCRIPT_LAMBDA_ARN  = local.fetch_transcript_arn
        ANTHROPIC_MODEL_IDENTIFIER   = "claude-2"
        ENDPOINT_URL                 = "https://api.anthropic.com/v1/complete"
        PROCESS_TRANSCRIPT           = "True"
        TOKEN_COUNT                  = "0"
        SUMMARY_PROMPT_SSM_PARAMETER = "${local.lob}-LLMPromptSummaryTemplate"
      }
    }

    async_transcript_summary = {
      function_name = "async-transcript-summary-${local.lob}"
      role_key      = "async_transcript_summary"
      runtime       = "python3.12"
      architectures = ["x86_64"]
      memory_size   = 128
      timeout       = 240
      filename      = "async-transcript-summary.zip"
      handler       = "lambda_function.handler"
      use_layer     = true
      environment = {
        TRANSCRIPT_SUMMARY_FUNCTION_ARN = local.bedrock_summary_arn
        CALL_DATA_STREAM_NAME           = module.lca_kinesis.stream_name
        BOTO_READ_TIMEOUT               = "60"
      }
    }

    async_agent_assist = {
      function_name = "async-agent-assist-${local.lob}"
      role_key      = "async_agent_assist"
      runtime       = "python3.12"
      architectures = ["x86_64"]
      memory_size   = 128
      timeout       = 60
      filename      = "async-agent-assist.zip"
      handler       = "lambda_function.handler"
      use_layer     = true
      environment = {
        CALL_DATA_STREAM_NAME            = module.lca_kinesis.stream_name
        DYNAMODB_TABLE_NAME              = module.lca_dynamodb.event_sourcing_table_name
        LEX_BOT_ID                       = "Pending AgentAssistSetup"
        LEX_BOT_ALIAS_ID                 = "Pending AgentAssistSetup"
        LEX_BOT_LOCALE_ID                = "Pending AgentAssistSetup"
        IS_LEX_AGENT_ASSIST_ENABLED      = tostring(var.is_lex_agent_assist_enabled)
        IS_LAMBDA_AGENT_ASSIST_ENABLED   = tostring(var.is_lambda_agent_assist_enabled)
        LAMBDA_AGENT_ASSIST_FUNCTION_ARN = ""
      }
    }

    # NOTE: email_domain_verify is created in lca-cognito-baseline
    # (with Cognito lambda trigger wiring), not here.

    contact_event_processor = {
      function_name = "contact-event-processor-${local.lob}"
      role_key      = "contact_event_processor"
      runtime       = "python3.12"
      architectures = ["x86_64"]
      memory_size   = 128
      timeout       = 20
      filename      = "contact-event-processor.zip"
      handler       = "index.handler"
      use_layer     = false
      environment = {
        KINESIS_STREAM_NAME       = module.lca_kinesis.stream_name
        EVENT_SOURCING_TABLE_NAME = module.lca_dynamodb.event_sourcing_table_name
        WAIT_FOR_CALL_SECS        = "15"
      }
    }

    associate_instance = {
      function_name = "associate-instance-${local.lob}"
      role_key      = "associate_instance"
      runtime       = "python3.12"
      architectures = ["x86_64"]
      memory_size   = 128
      timeout       = 900
      filename      = "associate-instance.zip"
      handler       = "index.handler"
      use_layer     = false
      environment   = {}
    }

    # NOTE: update_lca_settings and llm_prompt_upload are created in
    # lca-ssm-baseline (with seed invocation wiring), not here.

  }
}

#########################################
# MODULE CALLS — IN DEPENDENCY ORDER
#########################################

# ── GROUP 1 — No dependencies ──

module "lca_dynamodb" {
  source                      = "./modules/lca-dynamodb-baseline"
  lob                         = local.lob
  dynamodb_expiration_in_days = var.dynamodb_expiration_in_days
}

module "lca_kinesis" {
  source = "./modules/lca-kinesis-baseline"
  lob    = local.lob
}

module "lca_storage" {
  source                             = "./modules/lca-storage-baseline"
  lob                                = local.lob
  audio_recording_expiration_in_days = var.audio_recording_expiration_in_days
}

module "lca_notifications" {
  source     = "./modules/lca-notifications-baseline"
  lob        = local.lob
  account_id = var.account_id
}

# ── GROUP 2 — Needs Storage ──

module "lca_frontend" {
  source                 = "./modules/lca-frontend-baseline"
  lob                    = local.lob
  region                 = var.aws_region
  account_id             = var.account_id
  webapp_bucket_name     = module.lca_storage.webapp_bucket_name
  webapp_bucket_arn      = module.lca_storage.webapp_bucket_arn
  cloudfront_price_class = var.cloudfront_price_class

  depends_on = [
    module.lca_storage
  ]
}

# ── GROUP 3 — Needs DynamoDB, Storage, Kinesis, Notifications ──

module "lca_iam" {
  source                     = "./modules/lca-iam-baseline"
  lob                        = local.lob
  account_id                 = var.account_id
  region                     = var.aws_region
  event_sourcing_table_arn   = module.lca_dynamodb.event_sourcing_table_arn
  llm_prompt_table_arn       = module.lca_dynamodb.llm_prompt_table_arn
  lca_settings_parameter_arn = local.lca_settings_parameter_arn
  connect_instance_arn       = var.lob.connect_instance_arn
  call_data_stream_arn       = module.lca_kinesis.stream_arn
  sns_topic_arn              = module.lca_notifications.sns_topic_arn

  depends_on = [
    module.lca_dynamodb,
    module.lca_storage,
    module.lca_kinesis,
    module.lca_notifications
  ]
}

# ── GROUP 4 — Needs IAM, DynamoDB ──

module "lca_ssm" {
  source                    = "./modules/lca-ssm-baseline"
  lob                       = local.lob
  region                    = var.aws_region
  account_id                = var.account_id
  category_alert_regex      = var.category_alert_regex
  llm_prompt_table_name     = module.lca_dynamodb.llm_prompt_table_name
  update_settings_role_arn  = module.lca_iam.role_arns["update_lca_settings"]
  llm_prompt_upload_role_arn = module.lca_iam.role_arns["llm_prompt_upload"]

  depends_on = [
    module.lca_iam,
    module.lca_dynamodb
  ]
}

# ── GROUP 5 — Needs IAM, Storage, SSM, Frontend ──

module "lca_cognito" {
  source                      = "./modules/lca-cognito-baseline"
  lob                         = local.lob
  region                      = var.aws_region
  account_id                  = var.account_id
  admin_email                 = var.lob.admin_email
  allowed_email_domain        = var.lob.allowed_email_domain
  email_domain_verify_role_arn = module.lca_iam.role_arns["email_domain_verify"]
  recordings_bucket_arn       = module.lca_storage.recordings_bucket_arn
  recordings_bucket_name      = module.lca_storage.recordings_bucket_name
  settings_parameter_name     = module.lca_ssm.settings_parameter_name
  lca_settings_parameter_arn  = local.lca_settings_parameter_arn
  cloudfront_domain           = module.lca_frontend.cloudfront_domain_name

  depends_on = [
    module.lca_iam,
    module.lca_storage,
    module.lca_ssm,
    module.lca_frontend
  ]
}

# ── GROUP 6 — Needs Cognito, DynamoDB, IAM ──

module "lca_appsync" {
  source                    = "./modules/lca-appsync-baseline"
  lob                       = local.lob
  region                    = var.aws_region
  user_pool_id              = module.lca_cognito.user_pool_id
  user_pool_client_id       = module.lca_cognito.user_pool_client_id
  event_sourcing_table_name = module.lca_dynamodb.event_sourcing_table_name
  event_sourcing_table_arn  = module.lca_dynamodb.event_sourcing_table_arn
  appsync_cwl_role_arn      = module.lca_iam.role_arns["appsync_cwl"]
  appsync_dynamodb_role_arn = module.lca_iam.role_arns["appsync_dynamodb"]

  depends_on = [
    module.lca_cognito,
    module.lca_dynamodb,
    module.lca_iam
  ]
}

# ── GROUP 7 — Needs everything above ──

module "lca_lambda" {
  source               = "./modules/lca-lambda-baseline"
  lob                  = local.lob
  region               = var.aws_region
  account_id           = var.account_id
  lambda_functions     = local.resolved_lca_lambdas
  role_arns            = module.lca_iam.role_arns
  consumer_arn         = module.lca_kinesis.consumer_arn
  connect_instance_arn = var.lob.connect_instance_arn
  call_data_stream_arn = module.lca_kinesis.stream_arn

  depends_on = [
    module.lca_iam,
    module.lca_appsync,
    module.lca_ssm,
    module.lca_kinesis,
    module.lca_notifications,
    module.lca_dynamodb
  ]
}

# ── GROUP 8 — Needs Lambda, Kinesis, DynamoDB, IAM ──

module "lca_connect" {
  source                               = "./modules/lca-connect-baseline"
  lob                                  = local.lob
  region                               = var.aws_region
  account_id                           = var.account_id
  connect_instance_arn                 = var.lob.connect_instance_arn
  call_data_stream_name                = module.lca_kinesis.stream_name
  call_data_stream_arn                 = module.lca_kinesis.stream_arn
  event_sourcing_table_name            = module.lca_dynamodb.event_sourcing_table_name
  event_sourcing_table_arn             = module.lca_dynamodb.event_sourcing_table_arn
  call_event_processor_role_name       = module.lca_iam.role_names["call_event_processor"]
  contact_event_processor_role_arn     = module.lca_iam.role_arns["contact_event_processor"]
  associate_instance_function_name     = module.lca_lambda.function_names["associate_instance"]
  contact_event_processor_function_arn = module.lca_lambda.function_arns["contact_event_processor"]

  depends_on = [
    module.lca_lambda,
    module.lca_kinesis,
    module.lca_dynamodb,
    module.lca_iam
  ]
}
