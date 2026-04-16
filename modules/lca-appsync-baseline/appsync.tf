resource "aws_appsync_graphql_api" "main" {
  name                = "appsync-api-${var.lob}"
  authentication_type = "AMAZON_COGNITO_USER_POOLS"

  user_pool_config {
    user_pool_id   = var.user_pool_id
    aws_region     = var.region
    default_action = "ALLOW"
  }

  additional_authentication_provider {
    authentication_type = "AWS_IAM"
  }

  log_config {
    cloudwatch_logs_role_arn = var.appsync_cwl_role_arn
    field_log_level          = "ALL"
    exclude_verbose_content  = false
  }

  schema = file("${path.module}/../../appsync-files/schema.graphql")

  tags = {
    Project     = "LCA"
    LOB         = var.lob
    ManagedBy   = "Terraform"
    Environment = "production"
  }
}

resource "aws_appsync_datasource" "call_event_sourcing" {
  api_id           = aws_appsync_graphql_api.main.id
  name             = "CallEventSourcing"
  type             = "AMAZON_DYNAMODB"
  service_role_arn = var.appsync_dynamodb_role_arn

  dynamodb_config {
    table_name = var.event_sourcing_table_name
    region     = var.region
  }
}

resource "aws_appsync_api_cache" "main" {
  api_id               = aws_appsync_graphql_api.main.id
  type                 = "R4_LARGE"
  api_caching_behavior = "PER_RESOLVER_CACHING"
  ttl                  = 30
}

# ── Mutation Resolvers ──

resource "aws_appsync_resolver" "create_call" {
  api_id      = aws_appsync_graphql_api.main.id
  type        = "Mutation"
  field       = "createCall"
  data_source = aws_appsync_datasource.call_event_sourcing.name

  request_template  = file("${path.module}/../../appsync-files/resolvers/createCall.request.vtl")
  response_template = file("${path.module}/../../appsync-files/resolvers/createCall.response.vtl")

  depends_on = [aws_appsync_datasource.call_event_sourcing]
}

resource "aws_appsync_resolver" "update_call_status" {
  api_id      = aws_appsync_graphql_api.main.id
  type        = "Mutation"
  field       = "updateCallStatus"
  data_source = aws_appsync_datasource.call_event_sourcing.name

  request_template  = file("${path.module}/../../appsync-files/resolvers/update.request.vtl")
  response_template = file("${path.module}/../../appsync-files/resolvers/mutation.response.vtl")

  depends_on = [aws_appsync_datasource.call_event_sourcing]
}

resource "aws_appsync_resolver" "update_recording_url" {
  api_id      = aws_appsync_graphql_api.main.id
  type        = "Mutation"
  field       = "updateRecordingUrl"
  data_source = aws_appsync_datasource.call_event_sourcing.name

  request_template  = file("${path.module}/../../appsync-files/resolvers/update.request.vtl")
  response_template = file("${path.module}/../../appsync-files/resolvers/mutation.response.vtl")

  depends_on = [aws_appsync_datasource.call_event_sourcing]
}

resource "aws_appsync_resolver" "update_pca_url" {
  api_id      = aws_appsync_graphql_api.main.id
  type        = "Mutation"
  field       = "updatePcaUrl"
  data_source = aws_appsync_datasource.call_event_sourcing.name

  request_template  = file("${path.module}/../../appsync-files/resolvers/update.request.vtl")
  response_template = file("${path.module}/../../appsync-files/resolvers/mutation.response.vtl")

  depends_on = [aws_appsync_datasource.call_event_sourcing]
}

resource "aws_appsync_resolver" "update_agent" {
  api_id      = aws_appsync_graphql_api.main.id
  type        = "Mutation"
  field       = "updateAgent"
  data_source = aws_appsync_datasource.call_event_sourcing.name

  request_template  = file("${path.module}/../../appsync-files/resolvers/update.request.vtl")
  response_template = file("${path.module}/../../appsync-files/resolvers/mutation.response.vtl")

  depends_on = [aws_appsync_datasource.call_event_sourcing]
}

resource "aws_appsync_resolver" "add_call_category" {
  api_id      = aws_appsync_graphql_api.main.id
  type        = "Mutation"
  field       = "addCallCategory"
  data_source = aws_appsync_datasource.call_event_sourcing.name

  request_template  = file("${path.module}/../../appsync-files/resolvers/update.request.vtl")
  response_template = file("${path.module}/../../appsync-files/resolvers/mutation.response.vtl")

  depends_on = [aws_appsync_datasource.call_event_sourcing]
}

resource "aws_appsync_resolver" "add_issues_detected" {
  api_id      = aws_appsync_graphql_api.main.id
  type        = "Mutation"
  field       = "addIssuesDetected"
  data_source = aws_appsync_datasource.call_event_sourcing.name

  request_template  = file("${path.module}/../../appsync-files/resolvers/update.request.vtl")
  response_template = file("${path.module}/../../appsync-files/resolvers/mutation.response.vtl")

  depends_on = [aws_appsync_datasource.call_event_sourcing]
}

resource "aws_appsync_resolver" "add_call_summary_text" {
  api_id      = aws_appsync_graphql_api.main.id
  type        = "Mutation"
  field       = "addCallSummaryText"
  data_source = aws_appsync_datasource.call_event_sourcing.name

  request_template  = file("${path.module}/../../appsync-files/resolvers/update.request.vtl")
  response_template = file("${path.module}/../../appsync-files/resolvers/mutation.response.vtl")

  depends_on = [aws_appsync_datasource.call_event_sourcing]
}

resource "aws_appsync_resolver" "update_call_aggregation" {
  api_id      = aws_appsync_graphql_api.main.id
  type        = "Mutation"
  field       = "updateCallAggregation"
  data_source = aws_appsync_datasource.call_event_sourcing.name

  request_template  = file("${path.module}/../../appsync-files/resolvers/update.request.vtl")
  response_template = file("${path.module}/../../appsync-files/resolvers/mutation.response.vtl")

  depends_on = [aws_appsync_datasource.call_event_sourcing]
}

resource "aws_appsync_resolver" "add_transcript_segment" {
  api_id      = aws_appsync_graphql_api.main.id
  type        = "Mutation"
  field       = "addTranscriptSegment"
  data_source = aws_appsync_datasource.call_event_sourcing.name

  request_template  = file("${path.module}/../../appsync-files/resolvers/addTranscriptSegment.request.vtl")
  response_template = file("${path.module}/../../appsync-files/resolvers/mutation.response.vtl")

  depends_on = [aws_appsync_datasource.call_event_sourcing]
}

# ── Query Resolvers ──

resource "aws_appsync_resolver" "get_call" {
  api_id      = aws_appsync_graphql_api.main.id
  type        = "Query"
  field       = "getCall"
  data_source = aws_appsync_datasource.call_event_sourcing.name

  request_template  = file("${path.module}/../../appsync-files/resolvers/getCall.request.vtl")
  response_template = "$util.toJson($context.result)"

  depends_on = [aws_appsync_datasource.call_event_sourcing]
}

resource "aws_appsync_resolver" "list_calls_date_hour" {
  api_id      = aws_appsync_graphql_api.main.id
  type        = "Query"
  field       = "listCallsDateHour"
  data_source = aws_appsync_datasource.call_event_sourcing.name

  request_template  = file("${path.module}/../../appsync-files/resolvers/listCallsDateHour.request.vtl")
  response_template = file("${path.module}/../../appsync-files/resolvers/listCalls.response.vtl")

  depends_on = [aws_appsync_datasource.call_event_sourcing]
}

resource "aws_appsync_resolver" "list_calls_date_shard" {
  api_id      = aws_appsync_graphql_api.main.id
  type        = "Query"
  field       = "listCallsDateShard"
  data_source = aws_appsync_datasource.call_event_sourcing.name

  request_template  = file("${path.module}/../../appsync-files/resolvers/listCallsDateShard.request.vtl")
  response_template = file("${path.module}/../../appsync-files/resolvers/listCalls.response.vtl")

  depends_on = [aws_appsync_datasource.call_event_sourcing]
}

resource "aws_appsync_resolver" "list_calls" {
  api_id      = aws_appsync_graphql_api.main.id
  type        = "Query"
  field       = "listCalls"
  data_source = aws_appsync_datasource.call_event_sourcing.name

  request_template  = file("${path.module}/../../appsync-files/resolvers/listCalls.request.vtl")
  response_template = file("${path.module}/../../appsync-files/resolvers/listCalls.response.vtl")

  depends_on = [aws_appsync_datasource.call_event_sourcing]
}

resource "aws_appsync_resolver" "get_transcript_segments" {
  api_id      = aws_appsync_graphql_api.main.id
  type        = "Query"
  field       = "getTranscriptSegments"
  data_source = aws_appsync_datasource.call_event_sourcing.name

  request_template  = file("${path.module}/../../appsync-files/resolvers/getTranscriptSegments.request.vtl")
  response_template = file("${path.module}/../../appsync-files/resolvers/getTranscriptSegments.response.vtl")

  depends_on = [aws_appsync_datasource.call_event_sourcing]
}

resource "aws_appsync_resolver" "get_transcript_segments_with_sentiment" {
  api_id      = aws_appsync_graphql_api.main.id
  type        = "Query"
  field       = "getTranscriptSegmentsWithSentiment"
  data_source = aws_appsync_datasource.call_event_sourcing.name

  request_template  = file("${path.module}/../../appsync-files/resolvers/getTranscriptSegmentsWithSentiment.request.vtl")
  response_template = file("${path.module}/../../appsync-files/resolvers/getTranscriptSegmentsWithSentiment.response.vtl")

  depends_on = [aws_appsync_datasource.call_event_sourcing]
}
