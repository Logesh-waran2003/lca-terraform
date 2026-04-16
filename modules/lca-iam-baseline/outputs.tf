output "role_arns" {
  value = merge(
    { for k, v in aws_iam_role.roles : k => v.arn },
    {
      cognito_authorized  = aws_iam_role.cognito_authorized.arn
      agent_assist_unauth = aws_iam_role.agent_assist_unauth.arn
    }
  )
}

output "role_names" {
  value = merge(
    { for k, v in aws_iam_role.roles : k => v.name },
    {
      cognito_authorized  = aws_iam_role.cognito_authorized.name
      agent_assist_unauth = aws_iam_role.agent_assist_unauth.name
    }
  )
}
