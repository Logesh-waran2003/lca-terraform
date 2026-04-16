resource "aws_lambda_layer_version" "transcript_enrichment" {
  layer_name          = "transcript-enrichment-layer-${var.lob}"
  filename            = "${path.module}/../../lambda-files/transcript-enrichment-layer.zip"
  source_code_hash    = filebase64sha256("${path.module}/../../lambda-files/transcript-enrichment-layer.zip")
  compatible_runtimes = ["python3.12"]
  compatible_architectures = ["arm64"]
}

resource "aws_lambda_function" "functions" {
  for_each = var.lambda_functions

  function_name    = each.value.function_name
  role             = var.role_arns[each.value.role_key]
  handler          = each.value.handler
  runtime          = each.value.runtime
  filename         = "${path.module}/../../lambda-files/${each.value.filename}"
  source_code_hash = filebase64sha256("${path.module}/../../lambda-files/${each.value.filename}")
  memory_size      = each.value.memory_size
  timeout          = each.value.timeout
  architectures    = each.value.architectures
  publish          = true

  layers = each.value.use_layer ? [aws_lambda_layer_version.transcript_enrichment.arn] : []

  dynamic "environment" {
    for_each = length(each.value.environment) > 0 ? [1] : []
    content {
      variables = each.value.environment
    }
  }

  tags = {
    Project     = "LCA"
    LOB         = var.lob
    ManagedBy   = "Terraform"
    Environment = "production"
  }
}

resource "aws_lambda_permission" "connect_invoke" {
  for_each = aws_lambda_function.functions

  statement_id  = "AllowConnectInvoke-${each.key}"
  action        = "lambda:InvokeFunction"
  function_name = each.value.function_name
  principal     = "connect.amazonaws.com"
  source_arn    = "arn:aws:connect:${var.region}:${var.account_id}:instance/*"
}

resource "aws_lambda_event_source_mapping" "kinesis_trigger" {
  event_source_arn                   = var.consumer_arn
  function_name                      = aws_lambda_function.functions["call_event_processor"].arn
  starting_position                  = "LATEST"
  batch_size                         = 200
  maximum_batching_window_in_seconds = 0
  maximum_retry_attempts             = 2
  bisect_batch_on_function_error     = true
  parallelization_factor             = 10
  tumbling_window_in_seconds         = 0
  enabled                            = true
}

resource "null_resource" "associate_connect_instance" {
  triggers = {
    function_name        = aws_lambda_function.functions["associate_instance"].function_name
    connect_instance_arn = var.connect_instance_arn
    stream_arn           = var.call_data_stream_arn
  }

  provisioner "local-exec" {
    command = "aws lambda invoke --function-name ${aws_lambda_function.functions["associate_instance"].function_name} --payload \"{\\\"ConnectInstanceArn\\\":\\\"${var.connect_instance_arn}\\\",\\\"CallDataStreamArn\\\":\\\"${var.call_data_stream_arn}\\\"}\" --cli-binary-format raw-in-base64-out --region ${var.region} associate-response.json"
  }

  depends_on = [aws_lambda_function.functions]
}
