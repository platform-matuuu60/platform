variable "name" {
  description = "Application name; used for the function, the API and the IAM role."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,40}$", var.name))
    error_message = "name must be lowercase alphanumeric with dashes, 2-41 characters, starting with a letter."
  }
}

variable "source_dir" {
  description = "Directory with the function code; it is zipped as is."
  type        = string
}

variable "runtime" {
  description = "Lambda runtime identifier."
  type        = string
  default     = "python3.12"
}

variable "handler" {
  description = "Function entrypoint, for example handler.handler."
  type        = string
  default     = "handler.handler"
}

variable "memory_size" {
  description = "Function memory in MB."
  type        = number
  default     = 128
}

variable "timeout" {
  description = "Function timeout in seconds."
  type        = number
  default     = 10
}

variable "environment" {
  description = "Environment variables for the function."
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Tags applied to every resource."
  type        = map(string)
  default     = {}
}
