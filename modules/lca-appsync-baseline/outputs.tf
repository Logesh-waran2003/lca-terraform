output "graphql_url" {
  value = aws_appsync_graphql_api.main.uris["GRAPHQL"]
}

output "api_id" {
  value = aws_appsync_graphql_api.main.id
}

output "api_arn" {
  value = aws_appsync_graphql_api.main.arn
}
