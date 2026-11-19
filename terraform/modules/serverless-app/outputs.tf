output "function_name" {
  description = "Lambda function name."
  value       = aws_lambda_function.this.function_name
}

output "api_id" {
  description = "HTTP API identifier."
  value       = aws_apigatewayv2_api.this.id
}

output "api_endpoint" {
  description = "Base URL of the HTTP API ($default stage)."
  value       = aws_apigatewayv2_api.this.api_endpoint
}
